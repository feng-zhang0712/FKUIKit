import Foundation

/// Generic concrete endpoint implementation for quick request creation.
///
/// `FKEndpoint` is useful when you do not need a custom request type per API
/// and want to build requests inline while keeping `Requestable` compatibility.
public struct FKEndpoint<Response: Decodable & Sendable>: Requestable {
  /// Endpoint path appended to configured environment base URL.
  public let path: String
  /// HTTP method used by the request.
  public let method: HTTPMethod
  /// URL query parameters.
  public let queryItems: [String: String]
  /// Body parameters before encoding.
  public let bodyParameters: [String: Any]
  /// Request-level custom headers.
  public let headers: [String: String]
  /// Parameter encoding strategy.
  public let encoding: ParameterEncoding
  /// Cache policy used by the network client.
  public let cachePolicy: NetworkCachePolicy
  /// Additional behavior flags such as deduplication.
  public let behavior: NetworkRequestBehavior
  /// Optional mocked response data used when mock mode is enabled.
  public let mockData: Data?

  /// Creates an endpoint object.
  ///
  /// - Parameters:
  ///   - path: Endpoint path relative to base URL.
  ///   - method: HTTP method.
  ///   - queryItems: Query parameters.
  ///   - bodyParameters: Request body parameters.
  ///   - headers: Request-specific headers.
  ///   - encoding: Body encoding mode.
  ///   - cachePolicy: Cache behavior for this request.
  ///   - behavior: Additional dispatch behavior.
  ///   - mockData: Static response used in mock mode.
  public init(
    path: String,
    method: HTTPMethod = .get,
    queryItems: [String: String] = [:],
    bodyParameters: [String: Any] = [:],
    headers: [String: String] = [:],
    encoding: ParameterEncoding = .json,
    cachePolicy: NetworkCachePolicy = .none,
    behavior: NetworkRequestBehavior = .normal,
    mockData: Data? = nil
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.bodyParameters = bodyParameters
    self.headers = headers
    self.encoding = encoding
    self.cachePolicy = cachePolicy
    self.behavior = behavior
    self.mockData = mockData
  }
}
