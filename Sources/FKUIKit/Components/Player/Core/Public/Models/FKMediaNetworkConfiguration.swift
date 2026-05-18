import Foundation

/// Network retry, timeout, and reachability-related settings.
public struct FKMediaNetworkConfiguration: Sendable, Equatable {
  public var maxRetryCount: Int
  public var retryBackoffBase: TimeInterval
  public var connectionTimeout: TimeInterval
  public var readTimeout: TimeInterval
  public var allowsCellularAccess: Bool
  public var allowsConstrainedNetworkAccess: Bool

  public init(
    maxRetryCount: Int = 3,
    retryBackoffBase: TimeInterval = 1.0,
    connectionTimeout: TimeInterval = 30,
    readTimeout: TimeInterval = 60,
    allowsCellularAccess: Bool = true,
    allowsConstrainedNetworkAccess: Bool = true
  ) {
    self.maxRetryCount = maxRetryCount
    self.retryBackoffBase = retryBackoffBase
    self.connectionTimeout = connectionTimeout
    self.readTimeout = readTimeout
    self.allowsCellularAccess = allowsCellularAccess
    self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
  }

  public static let `default` = FKMediaNetworkConfiguration()
}
