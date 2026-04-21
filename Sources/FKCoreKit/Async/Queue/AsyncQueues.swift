import Foundation

// MARK: - Global & serial queue helpers

/// Factory-style helpers for common `DispatchQueue` patterns used across an app.
///
/// All methods return system queues or new serial queues; callers retain the returned queue if needed.
public enum FKAsyncQueues {
  /// Returns `DispatchQueue.global(qos: qos)`.
  ///
  /// - Parameter qos: Quality-of-service class (defaults to `.default`).
  public static func global(qos: DispatchQoS = .default) -> DispatchQueue {
    DispatchQueue.global(qos: qos.qosClass)
  }

  /// Serial queue for ordered, one-at-a-time background work.
  ///
  /// - Parameters:
  ///   - label: Reverse-DNS label (e.g. `com.app.module.serial`).
  ///   - qos: Target QoS for the queue.
  public static func serial(label: String, qos: DispatchQoS = .utility) -> DispatchQueue {
    DispatchQueue(label: label, qos: qos, attributes: [], autoreleaseFrequency: .workItem, target: nil)
  }

  /// Concurrent queue with an optional barrier-capable attribute (use barriers manually if needed).
  ///
  /// - Parameters:
  ///   - label: Reverse-DNS label.
  ///   - qos: Target QoS.
  public static func concurrent(label: String, qos: DispatchQoS = .default) -> DispatchQueue {
    DispatchQueue(label: label, qos: qos, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
  }
}
