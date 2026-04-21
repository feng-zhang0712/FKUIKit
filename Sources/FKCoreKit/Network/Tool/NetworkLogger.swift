import Foundation

/// Default logger implementation for FKNetwork.
///
/// Logs are emitted only in `DEBUG` builds to avoid noisy production output.
public struct FKDefaultNetworkLogger: NetworkLogger {
  /// Creates default logger.
  public init() {}

  /// Prints message with `[FKNetwork]` prefix in debug mode.
  ///
  /// - Parameter message: Log content.
  public func log(_ message: String) {
    #if DEBUG
    print("[FKNetwork] \(message)")
    #endif
  }
}
