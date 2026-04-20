import Foundation

/// Represents runtime backend environment.
public enum FKNetworkEnvironment: String, CaseIterable {
  /// Development environment.
  case development
  /// QA / staging environment.
  case testing
  /// Production environment.
  case production
}

/// Immutable configuration for one environment.
public struct FKEnvironmentConfig {
  /// Base URL used to build request paths.
  public let baseURL: URL
  /// Request timeout in seconds.
  public let timeout: TimeInterval
  /// Default headers appended to every request.
  public let defaultHeaders: [String: String]

  /// Creates an environment configuration.
  ///
  /// - Parameters:
  ///   - baseURL: Base API URL.
  ///   - timeout: Request timeout in seconds. Default is `30`.
  ///   - defaultHeaders: Default request headers.
  public init(baseURL: URL, timeout: TimeInterval = 30, defaultHeaders: [String: String] = [:]) {
    self.baseURL = baseURL
    self.timeout = timeout
    self.defaultHeaders = defaultHeaders
  }
}

/// Global runtime configuration used by `FKNetworkClient`.
///
/// This type is mutable by design so applications can update environment,
/// tokens, interceptors, and logger at runtime.
public final class FKNetworkConfiguration: @unchecked Sendable {
  /// Shared singleton used by default network client instances.
  public static let shared = FKNetworkConfiguration()

  /// Currently selected environment.
  public var environment: FKNetworkEnvironment
  /// Mapping from environment to concrete endpoint configuration.
  public var environmentMap: [FKNetworkEnvironment: FKEnvironmentConfig]
  /// Shared query parameters merged into every request.
  public var commonQueryItems: [String: String]
  /// Request interceptors executed before dispatch.
  public var requestInterceptors: [RequestInterceptor]
  /// Response interceptors executed before decoding.
  public var responseInterceptors: [ResponseInterceptor]
  /// Optional request signer.
  public var signer: RequestSigner?
  /// Optional token store used by auth interceptor and refresh flow.
  public var tokenStore: TokenStore?
  /// Optional token refresher used for 401 retry.
  public var tokenRefresher: TokenRefresher?
  /// Logger implementation for diagnostics.
  public var logger: NetworkLogger
  /// Optional reachability provider for preflight network checks.
  public var networkStatusProvider: NetworkStatusProviding?
  /// Enables mocked response path when request provides `mockData`.
  public var enableMock: Bool
  /// Optional SSL host filter. Return `true` to apply trust credential for host.
  public var shouldPinSSLHost: ((String) -> Bool)?
  /// Optional hook to encrypt request body parameters before encoding.
  public var encryptParameters: (([String: Any]) throws -> [String: Any])?
  /// Controls whether callback is dispatched to main queue.
  public var callbackOnMainQueue: Bool

  /// Guards access to computed properties that read mutable config maps.
  private let lock = NSLock()

  /// Creates a configuration object.
  ///
  /// - Parameters:
  ///   - environment: Default active environment.
  ///   - environmentMap: Environment to endpoint configuration mapping.
  ///   - commonQueryItems: Shared query parameters.
  ///   - requestInterceptors: Request interceptor chain.
  ///   - responseInterceptors: Response interceptor chain.
  ///   - signer: Optional request signer.
  ///   - tokenStore: Optional token storage.
  ///   - tokenRefresher: Optional token refresher.
  ///   - logger: Logger implementation.
  ///   - networkStatusProvider: Optional reachability provider.
  ///   - enableMock: Mock mode switch.
  ///   - shouldPinSSLHost: Optional SSL host strategy hook.
  ///   - encryptParameters: Optional parameter encryption hook.
  ///   - callbackOnMainQueue: Completion queue policy.
  public init(
    environment: FKNetworkEnvironment = .development,
    environmentMap: [FKNetworkEnvironment: FKEnvironmentConfig] = [:],
    commonQueryItems: [String: String] = [:],
    requestInterceptors: [RequestInterceptor] = [],
    responseInterceptors: [ResponseInterceptor] = [],
    signer: RequestSigner? = nil,
    tokenStore: TokenStore? = nil,
    tokenRefresher: TokenRefresher? = nil,
    logger: NetworkLogger = FKDefaultNetworkLogger(),
    networkStatusProvider: NetworkStatusProviding? = nil,
    enableMock: Bool = false,
    shouldPinSSLHost: ((String) -> Bool)? = nil,
    encryptParameters: (([String: Any]) throws -> [String: Any])? = nil,
    callbackOnMainQueue: Bool = true
  ) {
    self.environment = environment
    self.environmentMap = environmentMap
    self.commonQueryItems = commonQueryItems
    self.requestInterceptors = requestInterceptors
    self.responseInterceptors = responseInterceptors
    self.signer = signer
    self.tokenStore = tokenStore
    self.tokenRefresher = tokenRefresher
    self.logger = logger
    self.networkStatusProvider = networkStatusProvider
    self.enableMock = enableMock
    self.shouldPinSSLHost = shouldPinSSLHost
    self.encryptParameters = encryptParameters
    self.callbackOnMainQueue = callbackOnMainQueue
  }

  /// Returns active environment configuration in a thread-safe manner.
  public var current: FKEnvironmentConfig? {
    lock.lock()
    defer { lock.unlock() }
    return environmentMap[environment]
  }
}
