//
// FKNetworkClient.swift
//

import Foundation
import Combine

public actor FKNetworkClient {

  // MARK: - Properties

  public let configuration: FKNetworkConfiguration
  private let session: URLSession
  private let logger: FKNetworkLogger

  // MARK: - Init

  public init(configuration: FKNetworkConfiguration = FKNetworkConfiguration()) {
    self.configuration = configuration
    self.logger = FKNetworkLogger(logLevel: configuration.logLevel)

    let urlCache = URLCache(
      memoryCapacity: configuration.urlCacheMemoryCapacity,
      diskCapacity: configuration.urlCacheDiskCapacity
    )
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.urlCache = urlCache
    sessionConfig.requestCachePolicy = configuration.cachePolicy
    sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
    self.session = URLSession(configuration: sessionConfig)
  }

  // MARK: - async/await

  public func send<T: Decodable & Sendable>(
    _ request: FKRequest,
    decoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    let urlRequest = try buildURLRequest(request)
    let data = try await performWithRetry(urlRequest: urlRequest, retryCount: request.retryCount ?? configuration.retryCount)
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw FKNetworkError.decodingFailed(error)
    }
  }

  /// Fire-and-forget — returns raw Data.
  public func sendRaw(_ request: FKRequest) async throws -> Data {
    let urlRequest = try buildURLRequest(request)
    return try await performWithRetry(urlRequest: urlRequest, retryCount: request.retryCount ?? configuration.retryCount)
  }

  // MARK: - Combine

  public func publisher<T: Decodable & Sendable>(
    _ request: FKRequest,
    decoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, FKNetworkError> {
    let subject = PassthroughSubject<T, FKNetworkError>()
    Task {
      do {
        let result: T = try await self.send(request, decoder: decoder)
        subject.send(result)
        subject.send(completion: .finished)
      } catch let error as FKNetworkError {
        subject.send(completion: .failure(error))
      } catch {
        subject.send(completion: .failure(.unknown))
      }
    }
    return subject.eraseToAnyPublisher()
  }

  // MARK: - Build URLRequest

  private func buildURLRequest(_ request: FKRequest) throws -> URLRequest {
    let rawURL = configuration.baseURL + request.path
    guard var components = URLComponents(string: rawURL) else {
      throw FKNetworkError.invalidURL
    }

    if !request.queryItems.isEmpty {
      components.queryItems = (components.queryItems ?? []) + request.queryItems
    }

    guard let url = components.url else { throw FKNetworkError.invalidURL }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.timeoutInterval = request.timeoutInterval ?? configuration.timeoutInterval
    urlRequest.cachePolicy = request.cachePolicy ?? configuration.cachePolicy

    configuration.defaultHeaders.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
    request.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

    if let body = request.body {
      try applyBody(body, to: &urlRequest)
    }

    return urlRequest
  }

  private func applyBody(_ body: FKRequestBody, to request: inout URLRequest) throws {
    switch body {
    case .json(let dict):
      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dict)
      } catch {
        throw FKNetworkError.encodingFailed(error)
      }

    case .encodable(let value):
      do {
        request.httpBody = try JSONEncoder().encode(value)
      } catch {
        throw FKNetworkError.encodingFailed(error)
      }

    case .raw(let data, let contentType):
      request.httpBody = data
      request.setValue(contentType, forHTTPHeaderField: "Content-Type")

    case .formData(let dict):
      let encoded = dict.map { k, v in
        "\(k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k)=\(v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v)"
      }.joined(separator: "&")
      request.httpBody = encoded.data(using: .utf8)
      request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
  }

  // MARK: - Perform + Retry

  private func performWithRetry(urlRequest: URLRequest, retryCount: Int) async throws -> Data {
    var lastError: Error?
    for attempt in 0...max(0, retryCount) {
      if attempt > 0 {
        try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
      }
      do {
        return try await perform(urlRequest: urlRequest)
      } catch FKNetworkError.cancelled {
        throw FKNetworkError.cancelled
      } catch {
        lastError = error
      }
    }
    throw lastError ?? FKNetworkError.unknown
  }

  private func perform(urlRequest: URLRequest) async throws -> Data {
    logger.logRequest(urlRequest)
    let start = Date()
    do {
      let (data, response) = try await session.data(for: urlRequest)
      let duration = Date().timeIntervalSince(start)
      logger.logResponse(response, data: data, error: nil, duration: duration)

      guard let http = response as? HTTPURLResponse else { throw FKNetworkError.noResponse }
      guard (200..<300).contains(http.statusCode) else {
        throw FKNetworkError.httpError(statusCode: http.statusCode, data: data)
      }
      return data
    } catch let error as FKNetworkError {
      throw error
    } catch let urlError as URLError {
      let duration = Date().timeIntervalSince(start)
      logger.logResponse(nil, data: nil, error: urlError, duration: duration)
      switch urlError.code {
      case .cancelled:              throw FKNetworkError.cancelled
      case .timedOut:               throw FKNetworkError.timeout
      default:                      throw FKNetworkError.networkFailure(urlError)
      }
    } catch {
      throw FKNetworkError.networkFailure(error)
    }
  }
}
