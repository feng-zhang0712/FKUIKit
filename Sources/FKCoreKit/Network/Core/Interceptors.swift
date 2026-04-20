import Foundation

/// Request interceptor that injects Bearer authorization header.
public struct AuthHeaderInterceptor: RequestInterceptor {
  /// Token provider used to read current access token.
  public let tokenStore: TokenStore

  /// Creates auth header interceptor.
  ///
  /// - Parameter tokenStore: Token provider.
  public init(tokenStore: TokenStore) {
    self.tokenStore = tokenStore
  }

  /// Adds `Authorization: Bearer <token>` when token exists.
  ///
  /// - Parameter request: Original request.
  /// - Returns: Updated request with auth header.
  public func intercept(_ request: URLRequest) throws -> URLRequest {
    guard let token = tokenStore.accessToken, token.isEmpty == false else { return request }
    var mutable = request
    mutable.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return mutable
  }
}

/// Response interceptor placeholder for JSON responses.
///
/// This interceptor currently performs content-type guard only and returns
/// original data. It exists as an extension point for envelope normalization
/// or response decryption.
public struct JSONResponseInterceptor: ResponseInterceptor {
  /// Creates a JSON response interceptor.
  public init() {}

  /// Validates JSON content type and returns data unchanged.
  ///
  /// - Parameters:
  ///   - data: Raw response data.
  ///   - response: HTTP response metadata.
  /// - Returns: Original data.
  public func intercept(data: Data, response: HTTPURLResponse) throws -> Data {
    let contentType = (response.allHeaderFields["Content-Type"] as? String) ?? ""
    guard contentType.contains("application/json") else {
      return data
    }
    return data
  }
}

/// MD5 signer that attaches timestamp and signature headers.
///
/// Signature source format:
/// `<METHOD>|<PATH>|<TIMESTAMP>|<SECRET>`
public struct MD5RequestSigner: RequestSigner {
  /// Shared signing secret.
  private let secret: String

  /// Creates signer with a private secret.
  ///
  /// - Parameter secret: Secret key used in signature source string.
  public init(secret: String) {
    self.secret = secret
  }

  /// Signs request by adding `X-Timestamp` and `X-Signature` headers.
  ///
  /// - Parameter request: Original request.
  /// - Returns: Signed request.
  /// - Throws: `NetworkError.signingFailed` when request URL is unavailable.
  public func sign(_ request: URLRequest) throws -> URLRequest {
    guard let url = request.url else { throw NetworkError.signingFailed }
    var mutable = request
    let timestamp = String(Int(Date().timeIntervalSince1970))
    let source = "\(request.httpMethod ?? "GET")|\(url.path)|\(timestamp)|\(secret)"
    mutable.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
    mutable.setValue(source.fk_md5, forHTTPHeaderField: "X-Signature")
    return mutable
  }
}
