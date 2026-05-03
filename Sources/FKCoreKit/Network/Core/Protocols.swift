import Foundation

/// Describes a typed API request.
///
/// Conforming types define endpoint metadata, encoding behavior, cache policy,
/// and expected decoded response model.
public protocol Requestable {
  /// Decoded response model type for this request.
  associatedtype Response: Decodable & Sendable

  /// Endpoint path relative to configured base URL.
  var path: String { get }
  /// HTTP method used by the request.
  var method: HTTPMethod { get }
  /// Query parameters appended to URL.
  var queryItems: [String: String] { get }
  /// Body parameters encoded based on `encoding`.
  var bodyParameters: [String: Any] { get }
  /// Request-level custom headers.
  var headers: [String: String] { get }
  /// Parameter encoding strategy.
  var encoding: ParameterEncoding { get }
  /// Cache policy for this request.
  var cachePolicy: NetworkCachePolicy { get }
  /// Additional dispatch behavior flags.
  var behavior: NetworkRequestBehavior { get }
  /// Optional mocked payload used when global mock mode is enabled.
  var mockData: Data? { get }
}

/// Default request values to keep endpoint definitions concise.
public extension Requestable {
  /// Empty query parameters by default.
  var queryItems: [String: String] { [:] }
  /// Empty body parameters by default.
  var bodyParameters: [String: Any] { [:] }
  /// Empty custom headers by default.
  var headers: [String: String] { [:] }
  /// JSON body encoding by default.
  var encoding: ParameterEncoding { .json }
  /// No cache by default.
  var cachePolicy: NetworkCachePolicy { .none }
  /// Normal behavior by default.
  var behavior: NetworkRequestBehavior { .normal }
  /// No mock payload by default.
  var mockData: Data? { nil }
}

/// Abstraction over URLSession task creation.
///
/// Conforming to this protocol enables dependency injection for testing and
/// custom transport implementations without changing high-level client logic.
public protocol NetworkSession {
  /// Completion signature for data and upload tasks.
  typealias DataTaskCompletion = @Sendable (Data?, URLResponse?, Error?) -> Void
  /// Completion signature for download tasks.
  typealias DownloadTaskCompletion = @Sendable (URL?, URLResponse?, Error?) -> Void

  /// Creates a data task.
  ///
  /// - Parameters:
  ///   - request: Fully built URL request.
  ///   - completionHandler: Callback with data, response, and error.
  /// - Returns: Configured data task.
  func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTask
  /// Creates an upload task from local file.
  ///
  /// - Parameters:
  ///   - request: Upload request.
  ///   - fileURL: Local file URL to upload.
  ///   - completionHandler: Callback with server response payload.
  /// - Returns: Configured upload task.
  func uploadTask(
    with request: URLRequest,
    fromFile fileURL: URL,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionUploadTask
  /// Creates a download task.
  ///
  /// - Parameter request: Download request.
  /// - Returns: Configured download task.
  func downloadTask(with request: URLRequest) -> URLSessionDownloadTask
  /// Creates a resumable download task.
  ///
  /// - Parameter resumeData: Resume data captured from interrupted download.
  /// - Returns: Configured download task.
  func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask
}

/// Cache abstraction for in-memory and persistent storage layers.
///
/// Conforming types can provide custom cache engines while preserving the same
/// read/write contract used by `FKNetworkClient`.
public protocol Cacheable {
  /// Reads cached value by key.
  ///
  /// - Parameter key: Stable request cache key.
  /// - Returns: Cached payload if present and valid.
  func value(for key: String) -> Data?
  /// Stores value in cache.
  ///
  /// - Parameters:
  ///   - value: Raw payload data.
  ///   - key: Stable request cache key.
  ///   - ttl: Time-to-live in seconds.
  ///   - toDisk: Whether value should also be persisted to disk.
  func set(_ value: Data, for key: String, ttl: TimeInterval, toDisk: Bool)
  /// Removes a single cached value.
  ///
  /// - Parameter key: Target cache key.
  func removeValue(for key: String)
  /// Clears all cached entries.
  func removeAll()
}

/// Intercepts and mutates outbound requests before dispatch.
///
/// Use this protocol to inject cross-cutting concerns such as auth headers,
/// locale metadata, idempotency keys, or trace identifiers.
public protocol RequestInterceptor {
  /// Mutates outbound request.
  ///
  /// - Parameter request: Original request.
  /// - Returns: Updated request.
  /// - Throws: Any custom interceptor error.
  func intercept(_ request: URLRequest) throws -> URLRequest
}

/// Intercepts inbound response data before decoding.
///
/// Use this to normalize payload format, decrypt body data, or map envelope
/// structures before Codable parsing.
public protocol ResponseInterceptor {
  /// Mutates inbound response data.
  ///
  /// - Parameters:
  ///   - data: Raw response data.
  ///   - response: HTTP response metadata.
  /// - Returns: Updated data for decoding.
  /// - Throws: Any custom interceptor error.
  func intercept(data: Data, response: HTTPURLResponse) throws -> Data
}

/// Signs outbound requests to satisfy backend authentication policies.
public protocol RequestSigner {
  /// Attaches signature information to request.
  ///
  /// - Parameter request: Original request.
  /// - Returns: Signed request.
  /// - Throws: Signing-specific failure.
  func sign(_ request: URLRequest) throws -> URLRequest
}

/// Shared token storage abstraction.
///
/// Conforming types usually persist tokens in memory, keychain, or secure store.
public protocol TokenStore: AnyObject {
  /// Current access token used for authenticated calls.
  var accessToken: String? { get set }
  /// Refresh token used to obtain a new access token.
  var refreshToken: String? { get set }
}

/// Provides token refresh behavior for 401 retry flow.
///
/// Conforming types should call backend refresh API and return a valid new
/// access token through completion callback.
public protocol TokenRefresher {
  /// Refreshes access token.
  ///
  /// - Parameters:
  ///   - currentRefreshToken: Existing refresh token from token store.
  ///   - completion: Completion returning new access token or refresh error.
  func refreshToken(
    using currentRefreshToken: String?,
    completion: @escaping (Result<String, NetworkError>) -> Void
  )
}

/// Network reachability abstraction.
public protocol NetworkStatusProviding {
  /// Indicates whether network is currently reachable.
  var isReachable: Bool { get }
}

/// Logging abstraction used by network client.
public protocol NetworkLogger {
  /// Logs a network-related message.
  ///
  /// - Parameter message: Log string.
  func log(_ message: String)
}

/// Unified networking interface used by services, view models, and controllers.
///
/// Conforming type (`FKNetworkClient`) provides request APIs for closure and
/// async/await styles, plus upload/download capabilities.
public protocol Networkable: AnyObject {
  /// Sends a typed request using completion callback style.
  ///
  /// - Parameters:
  ///   - request: Typed request definition.
  ///   - completion: Result callback on configured callback queue.
  /// - Returns: Cancellable token for manual cancellation.
  @discardableResult
  func send<R: Requestable>(
    _ request: R,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) -> Cancellable

  /// Sends a typed request using async/await style.
  ///
  /// - Parameter request: Typed request definition.
  /// - Returns: Decoded response model.
  /// - Throws: `NetworkError` or wrapped underlying error.
  @discardableResult
  @available(iOS 13.0, macOS 10.15, *)
  func send<R: Requestable>(_ request: R) async throws -> R.Response

  /// Uploads file data.
  ///
  /// - Parameters:
  ///   - request: Upload URL request.
  ///   - fileURL: Local file URL.
  ///   - progress: Optional progress callback in [0, 1].
  ///   - completion: Upload completion callback.
  /// - Returns: Cancellable token for manual cancellation.
  @discardableResult
  func upload(
    _ request: URLRequest,
    fileURL: URL,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<Data, NetworkError>) -> Void
  ) -> Cancellable

  /// Downloads a file, optionally resuming from previous interruption.
  ///
  /// - Parameters:
  ///   - request: Download URL request.
  ///   - resumeData: Resume data from failed download, if available.
  ///   - progress: Optional progress callback in [0, 1].
  ///   - completion: Completion with temporary file URL and optional resume data.
  /// - Returns: Cancellable token for manual cancellation.
  @discardableResult
  func download(
    _ request: URLRequest,
    resumeData: Data?,
    progress: ((Double) -> Void)?,
    completion: @escaping (Result<(fileURL: URL, resumeData: Data?), NetworkError>) -> Void
  ) -> Cancellable
}

/// Lightweight cancellation handle abstraction.
public protocol Cancellable: AnyObject {
  /// Cancels the underlying network operation.
  func cancel()
}
