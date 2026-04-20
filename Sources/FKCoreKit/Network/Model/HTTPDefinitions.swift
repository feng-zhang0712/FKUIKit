import Foundation

/// Represents supported HTTP methods for request construction.
public enum HTTPMethod: String, CaseIterable {
  /// Retrieves resources without modifying server state.
  case get = "GET"
  /// Creates a new resource on server.
  case post = "POST"
  /// Replaces an existing resource.
  case put = "PUT"
  /// Partially updates an existing resource.
  case patch = "PATCH"
  /// Removes a resource.
  case delete = "DELETE"
  /// Retrieves response headers only.
  case head = "HEAD"
  /// Requests communication options for a given endpoint.
  case options = "OPTIONS"
}

/// Defines how request parameters are encoded into the outbound request.
public enum ParameterEncoding {
  /// Encodes parameters in query string.
  case query
  /// Encodes parameters as JSON body.
  case json
  /// Encodes parameters as `application/x-www-form-urlencoded` body.
  case formURLEncoded
}

/// Defines cache strategy for a request.
public enum NetworkCachePolicy {
  /// Disables cache read/write for the request.
  case none
  /// Uses in-memory cache with the given time-to-live.
  case memory(ttl: TimeInterval)
  /// Uses disk cache with the given time-to-live.
  case disk(ttl: TimeInterval)
  /// Uses both memory and disk cache with shared time-to-live.
  case memoryAndDisk(ttl: TimeInterval)
}

/// Defines optional execution behavior for request dispatching.
public enum NetworkRequestBehavior {
  /// Executes request normally.
  case normal
  /// Prevents duplicate in-flight requests with the same key.
  case idempotentDeduplicated
}

/// Wraps decoded response payload with HTTP metadata.
///
/// Use this type when business logic needs status code, headers, or raw body
/// in addition to decoded model value.
public struct NetworkResponse<T: Decodable> {
  /// Decoded model value.
  public let value: T
  /// HTTP status code from server response.
  public let statusCode: Int
  /// Raw response headers.
  public let headers: [AnyHashable: Any]
  /// Raw response data before decoding.
  public let rawData: Data

  /// Creates a typed network response.
  ///
  /// - Parameters:
  ///   - value: Decoded model object.
  ///   - statusCode: HTTP status code.
  ///   - headers: HTTP response headers.
  ///   - rawData: Raw payload bytes.
  public init(value: T, statusCode: Int, headers: [AnyHashable: Any], rawData: Data) {
    self.value = value
    self.statusCode = statusCode
    self.headers = headers
    self.rawData = rawData
  }
}
