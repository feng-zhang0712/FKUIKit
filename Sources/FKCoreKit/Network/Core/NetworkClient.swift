import Foundation

/**
 `FKNetworkClient` is the core request dispatcher of FKNetwork.

 Design responsibilities:
 - Build URL requests from `Requestable` definitions.
 - Apply request/response interceptors and request signer.
 - Support both callback and async/await APIs.
 - Handle token refresh retry flow on 401.
 - Integrate cache read/write and request deduplication.
 - Provide upload/download with progress callbacks.

 Usage notes:
 - Completions are dispatched on `config.callbackOnMainQueue` by default.
 - Shared mutable maps (progress/completion handlers) are lock-protected.
 - This class does not own business-level parsing rules beyond Codable decoding.
 */
public final class FKNetworkClient: NSObject, Networkable, URLSessionTaskDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
  /// Runtime configuration source.
  private let config: FKNetworkConfiguration
  /// Backing URLSession used for all task types.
  private var session: URLSession!
  /// Cache engine used by cache policies.
  private let cache: Cacheable
  /// Deduplicator for idempotent in-flight requests.
  private let deduplicator: FKRequestDeduplicator
  /// Queue used to dispatch client callbacks.
  private let callbackQueue: DispatchQueue
  /// Shared JSON decoder.
  private let decoder: JSONDecoder

  /// Upload progress handlers keyed by task identifier.
  private var uploadProgressHandlers: [Int: (Double) -> Void] = [:]
  /// Download progress handlers keyed by task identifier.
  private var downloadProgressHandlers: [Int: (Double) -> Void] = [:]
  /// Download completion handlers keyed by task identifier.
  private var downloadCompletions: [Int: (Result<(fileURL: URL, resumeData: Data?), NetworkError>) -> Void] = [:]
  /// Lock guarding mutable handler maps.
  private var lock = NSLock()

  /// Creates a network client.
  ///
  /// - Parameters:
  ///   - config: Runtime network configuration.
  ///   - sessionConfiguration: URLSession configuration.
  ///   - cache: Cache implementation.
  ///   - deduplicator: In-flight deduplication helper.
  ///   - decoder: Decoder used for `Requestable.Response`.
  public init(
    config: FKNetworkConfiguration = .shared,
    sessionConfiguration: URLSessionConfiguration = .default,
    cache: Cacheable = FKNetworkCache(),
    deduplicator: FKRequestDeduplicator = .init(),
    decoder: JSONDecoder = .init()
  ) {
    self.config = config
    self.cache = cache
    self.deduplicator = deduplicator
    self.decoder = decoder
    callbackQueue = config.callbackOnMainQueue ? .main : .global(qos: .userInitiated)
    sessionConfiguration.timeoutIntervalForRequest = config.current?.timeout ?? 30
    super.init()
    session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
  }

  /// Sends a typed request using completion callback.
  ///
  /// - Parameters:
  ///   - request: Request object conforming to `Requestable`.
  ///   - completion: Completion callback on configured callback queue.
  /// - Returns: Cancellable token.
  @discardableResult
  public func send<R: Requestable>(
    _ request: R,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) -> Cancellable {
    // Dispatch all results to configured callback queue for consistency.
    let callback: (Result<R.Response, NetworkError>) -> Void = { [callbackQueue] result in
      callbackQueue.async {
        completion(result)
      }
    }

    // Fast-fail before request building when network is known offline.
    if let provider = config.networkStatusProvider, provider.isReachable == false {
      callback(.failure(.offline))
      return NoopCancellable()
    }

    guard let built = try? buildRequest(from: request) else {
      callback(.failure(.invalidURL))
      return NoopCancellable()
    }
    let key = cacheKey(for: built)

    // Cache fast path.
    if case let .memory(ttl) = request.cachePolicy, let data = cache.value(for: key) {
      decode(data: data, request: request, statusCode: 200, headers: [:], completion: callback)
      config.logger.log("cache hit(memory), ttl: \(ttl), key: \(key)")
      return NoopCancellable()
    }
    if case let .disk(ttl) = request.cachePolicy, let data = cache.value(for: key) {
      decode(data: data, request: request, statusCode: 200, headers: [:], completion: callback)
      config.logger.log("cache hit(disk), ttl: \(ttl), key: \(key)")
      return NoopCancellable()
    }
    if case let .memoryAndDisk(ttl) = request.cachePolicy, let data = cache.value(for: key) {
      decode(data: data, request: request, statusCode: 200, headers: [:], completion: callback)
      config.logger.log("cache hit(memory+disk), ttl: \(ttl), key: \(key)")
      return NoopCancellable()
    }

    // Prevent duplicate in-flight request when deduplication is enabled.
    if request.behavior == .idempotentDeduplicated, deduplicator.shouldProceed(key: key) == false {
      callback(.failure(.businessError(code: -2, message: "Request deduplicated.")))
      return NoopCancellable()
    }

    // Mock path bypasses network transport but keeps decode behavior.
    if config.enableMock, let mockData = request.mockData {
      decode(data: mockData, request: request, statusCode: 200, headers: [:], completion: callback)
      deduplicator.complete(key: key)
      return NoopCancellable()
    }

    config.logger.log("➡️ \(built.httpMethod ?? "GET") \(built.url?.absoluteString ?? "")")
    let task = session.dataTask(with: built) { [weak self] data, response, error in
      guard let self else { return }
      defer {
        // Always release in-flight deduplication key.
        self.deduplicator.complete(key: key)
      }
      self.handleResponse(
        request: request,
        data: data,
        response: response,
        error: error,
        retried: false,
        originalRequest: built,
        completion: callback
      )
    }
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  /// Sends a typed request using async/await.
  ///
  /// - Parameter request: Request object conforming to `Requestable`.
  /// - Returns: Decoded response model.
  /// - Throws: `NetworkError` on failure.
  @available(iOS 13.0, macOS 10.15, *)
  public func send<R: Requestable>(_ request: R) async throws -> R.Response {
    try await withCheckedThrowingContinuation { continuation in
      _ = send(request) { result in
        switch result {
        case let .success(value):
          continuation.resume(returning: value)
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// Uploads a local file with optional progress callback.
  ///
  /// - Parameters:
  ///   - request: Upload URL request.
  ///   - fileURL: Local file path.
  ///   - progress: Optional progress callback in [0, 1].
  ///   - completion: Completion callback.
  /// - Returns: Cancellable token.
  @discardableResult
  public func upload(
    _ request: URLRequest,
    fileURL: URL,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<Data, NetworkError>) -> Void
  ) -> Cancellable {
    // URLSession invokes this completion after upload finishes or fails.
    let task = session.uploadTask(with: request, fromFile: fileURL) { [callbackQueue] data, response, error in
      let result: Result<Data, NetworkError>
      if let error {
        result = .failure(self.mapError(error))
      } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        result = .failure(.serverError(statusCode: http.statusCode, message: nil))
      } else {
        result = .success(data ?? .init())
      }
      callbackQueue.async {
        completion(result)
      }
    }
    if let progress {
      // Keep progress callback mapped by task id.
      lock.lock()
      uploadProgressHandlers[task.taskIdentifier] = progress
      lock.unlock()
    }
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  /// Downloads a file with optional resumable data and progress callback.
  ///
  /// - Parameters:
  ///   - request: Download URL request.
  ///   - resumeData: Resume data from interrupted task.
  ///   - progress: Optional progress callback in [0, 1].
  ///   - completion: Completion callback with temporary file URL.
  /// - Returns: Cancellable token.
  @discardableResult
  public func download(
    _ request: URLRequest,
    resumeData: Data?,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<(fileURL: URL, resumeData: Data?), NetworkError>) -> Void
  ) -> Cancellable {
    // Prefer resume data task when available.
    let task: URLSessionDownloadTask = if let resumeData {
      session.downloadTask(withResumeData: resumeData)
    } else {
      session.downloadTask(with: request)
    }
    if let progress {
      lock.lock()
      downloadProgressHandlers[task.taskIdentifier] = progress
      lock.unlock()
    }
    lock.lock()
    downloadCompletions[task.taskIdentifier] = completion
    lock.unlock()
    task.resume()
    return URLSessionTaskBox(task: task)
  }

  /// Central response pipeline shared by standard and retry requests.
  ///
  /// - Parameters:
  ///   - request: Original typed request.
  ///   - data: Raw payload data.
  ///   - response: URL response object.
  ///   - error: Transport error.
  ///   - retried: Indicates whether this is retry execution.
  ///   - originalRequest: URL request used for this execution.
  ///   - completion: Final completion callback.
  private func handleResponse<R: Requestable>(
    request: R,
    data: Data?,
    response: URLResponse?,
    error: Error?,
    retried: Bool,
    originalRequest: URLRequest,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) {
    if let error {
      completion(.failure(mapError(error)))
      return
    }
    guard let httpResponse = response as? HTTPURLResponse else {
      completion(.failure(.invalidResponse))
      return
    }
    guard var data else {
      completion(.failure(.noData))
      return
    }
    do {
      // Response interceptor chain can transform/decrypt payload.
      for interceptor in config.responseInterceptors {
        data = try interceptor.intercept(data: data, response: httpResponse)
      }
    } catch {
      completion(.failure(.underlying(error)))
      return
    }

    // Transparent token refresh and one-time retry.
    if httpResponse.statusCode == 401, retried == false {
      refreshTokenAndRetry(request: request, originalRequest: originalRequest, completion: completion)
      return
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))))
      return
    }
    storeCacheIfNeeded(request: request, data: data, for: cacheKey(for: originalRequest))
    decode(
      data: data,
      request: request,
      statusCode: httpResponse.statusCode,
      headers: httpResponse.allHeaderFields,
      completion: completion
    )
  }

  /// Executes token refresh flow and retries original request once.
  ///
  /// - Important: This method returns `.tokenRefreshFailed` when token store
  ///   or refresher is unavailable, or when refresh callback fails.
  private func refreshTokenAndRetry<R: Requestable>(
    request: R,
    originalRequest: URLRequest,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) {
    guard let refresher = config.tokenRefresher, let tokenStore = config.tokenStore else {
      completion(.failure(.tokenRefreshFailed))
      return
    }
    // Refresh token asynchronously, then replay original request with new auth.
    refresher.refreshToken(using: tokenStore.refreshToken) { [weak self] result in
      guard let self else { return }
      switch result {
      case let .success(token):
        // Persist new token before retrying.
        tokenStore.accessToken = token
        var retryRequest = originalRequest
        retryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = session.dataTask(with: retryRequest) { [weak self] data, response, error in
          self?.handleResponse(
            request: request,
            data: data,
            response: response,
            error: error,
            retried: true,
            originalRequest: retryRequest,
            completion: completion
          )
        }
        task.resume()
      case .failure:
        completion(.failure(.tokenRefreshFailed))
      }
    }
  }

  /// Builds `URLRequest` from endpoint and global configuration.
  ///
  /// - Parameter endpoint: Typed endpoint definition.
  /// - Returns: Built URL request ready for execution.
  /// - Throws: `NetworkError.invalidURL` or custom encryption/signing errors.
  private func buildRequest<R: Requestable>(from endpoint: R) throws -> URLRequest {
    guard let env = config.current else { throw NetworkError.invalidURL }
    guard var components = URLComponents(url: env.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
    else {
      throw NetworkError.invalidURL
    }
    let mergedQuery = config.commonQueryItems.merging(endpoint.queryItems) { _, latest in latest }
    if mergedQuery.isEmpty == false {
      // Sort query names for stable URL and deterministic cache keys.
      components.queryItems = mergedQuery.map { .init(name: $0.key, value: $0.value) }.sorted(by: { $0.name < $1.name })
    }
    guard let finalURL = components.url else { throw NetworkError.invalidURL }

    var request = URLRequest(url: finalURL)
    request.httpMethod = endpoint.method.rawValue
    request.timeoutInterval = env.timeout

    let mergedHeaders = env.defaultHeaders.merging(endpoint.headers) { _, latest in latest }
    mergedHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

    var payload = endpoint.bodyParameters
    if let encrypt = config.encryptParameters {
      // Optional payload encryption extension point.
      payload = try encrypt(payload)
    }
    switch endpoint.encoding {
    case .query:
      break
    case .json:
      if payload.isEmpty == false {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
    case .formURLEncoded:
      if payload.isEmpty == false {
        let form = payload.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: "&")
        request.httpBody = form.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      }
    }

    // Request interceptors are applied before signing.
    for interceptor in config.requestInterceptors {
      request = try interceptor.intercept(request)
    }
    // Signing should run after all request mutations.
    if let signer = config.signer {
      request = try signer.sign(request)
    }
    return request
  }

  /// Decodes typed response model from raw data.
  ///
  /// - Parameters:
  ///   - data: Raw payload data.
  ///   - request: Original typed request.
  ///   - statusCode: HTTP status code.
  ///   - headers: HTTP response headers.
  ///   - completion: Final completion callback.
  private func decode<R: Requestable>(
    data: Data,
    request: R,
    statusCode: Int,
    headers: [AnyHashable: Any],
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) {
    do {
      let value = try decoder.decode(R.Response.self, from: data)
      // Keep metadata object creation for optional debugging/extension.
      _ = NetworkResponse(value: value, statusCode: statusCode, headers: headers, rawData: data)
      completion(.success(value))
    } catch {
      completion(.failure(.decodingFailed(underlying: error)))
    }
  }

  /// Stores successful response into cache based on request policy.
  ///
  /// - Parameters:
  ///   - request: Original request carrying cache policy.
  ///   - data: Payload data to cache.
  ///   - key: Stable cache key.
  private func storeCacheIfNeeded<R: Requestable>(request: R, data: Data, for key: String) {
    switch request.cachePolicy {
    case .none:
      break
    case let .memory(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: false)
    case let .disk(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: true)
    case let .memoryAndDisk(ttl):
      cache.set(data, for: key, ttl: ttl, toDisk: true)
    }
  }

  /// Creates stable cache key from method, URL, and body.
  private func cacheKey(for request: URLRequest) -> String {
    let body = request.httpBody?.base64EncodedString() ?? ""
    return "\(request.httpMethod ?? "GET")|\(request.url?.absoluteString ?? "")|\(body)"
  }

  /// Maps Foundation transport errors to `NetworkError`.
  ///
  /// - Parameter error: Underlying system error.
  /// - Returns: Normalized `NetworkError`.
  private func mapError(_ error: Error) -> NetworkError {
    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      if nsError.code == NSURLErrorCancelled {
        return .requestCancelled
      }
      if nsError.code == NSURLErrorNotConnectedToInternet {
        return .offline
      }
      if nsError.code == NSURLErrorServerCertificateUntrusted {
        return .sslValidationFailed
      }
    }
    return .underlying(error)
  }

  /// URLSession upload progress callback.
  ///
  /// - Note: Progress handlers are looked up by task identifier.
  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    guard totalBytesExpectedToSend > 0 else { return }
    let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    lock.lock()
    let handler = uploadProgressHandlers[task.taskIdentifier]
    lock.unlock()
    handler?(value)
  }

  /// URLSession download progress callback.
  public func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    guard totalBytesExpectedToWrite > 0 else { return }
    let value = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    lock.lock()
    let handler = downloadProgressHandlers[downloadTask.taskIdentifier]
    lock.unlock()
    handler?(value)
  }

  /// URLSession download completion callback with temporary file URL.
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    lock.lock()
    let completion = downloadCompletions.removeValue(forKey: downloadTask.taskIdentifier)
    downloadProgressHandlers.removeValue(forKey: downloadTask.taskIdentifier)
    lock.unlock()
    callbackQueue.async {
      completion?(.success((fileURL: location, resumeData: nil)))
    }
  }

  /// URLSession task completion callback for error path.
  ///
  /// - Note: For interrupted downloads, resume data is extracted from `NSError`.
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error else { return }
    lock.lock()
    let completion = downloadCompletions.removeValue(forKey: task.taskIdentifier)
    uploadProgressHandlers.removeValue(forKey: task.taskIdentifier)
    downloadProgressHandlers.removeValue(forKey: task.taskIdentifier)
    lock.unlock()

    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    let mappedError = mapError(error)
    callbackQueue.async {
      completion?(.failure(resumeData == nil ? mappedError : .underlying(error)))
    }
  }

  /// URLSession authentication challenge callback.
  ///
  /// Applies basic server trust handling and optional host-based strategy hook.
  public func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    guard let trust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }
    let host = challenge.protectionSpace.host
    if config.shouldPinSSLHost?(host) == false {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    completionHandler(.useCredential, URLCredential(trust: trust))
  }
}

/// No-op cancellation object returned when no real task is created.
private final class NoopCancellable: Cancellable {
  /// Performs no action.
  func cancel() {}
}
