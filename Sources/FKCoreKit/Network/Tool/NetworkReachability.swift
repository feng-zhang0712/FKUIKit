import Foundation
import Network

/// Reachability provider based on `NWPathMonitor`.
///
/// This component exposes a lightweight boolean for preflight network checks.
/// It is intentionally simple and does not replace robust offline strategy.
@available(iOS 12.0, macOS 10.14, *)
public final class FKNetworkReachability: NetworkStatusProviding, @unchecked Sendable {
  /// Indicates current network reachability status.
  ///
  /// Default is `true` to avoid false negatives before first monitor callback.
  public private(set) var isReachable: Bool = true

  /// Path monitor instance.
  private let monitor = NWPathMonitor()
  /// Serial queue used by monitor callbacks.
  private let queue = DispatchQueue(label: "com.fkkit.network.reachability")

  /// Starts network path monitoring.
  public init() {
    monitor.pathUpdateHandler = { [weak self] path in
      self?.isReachable = path.status == .satisfied
    }
    monitor.start(queue: queue)
  }

  /// Stops network path monitoring.
  deinit {
    monitor.cancel()
  }
}
