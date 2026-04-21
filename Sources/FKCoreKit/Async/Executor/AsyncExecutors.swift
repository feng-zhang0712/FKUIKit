import Foundation

// MARK: - Serial executor

/// Runs closures strictly one after another on a private serial `DispatchQueue`.
public final class FKAsyncSerialExecutor: @unchecked Sendable {
  private let queue: DispatchQueue

  /// Creates an executor with a dedicated serial queue.
  ///
  /// - Parameters:
  ///   - label: Unique queue label (reverse-DNS recommended).
  ///   - qos: QoS for the underlying queue.
  public init(label: String, qos: DispatchQoS = .utility) {
    queue = FKAsyncQueues.serial(label: label, qos: qos)
  }

  /// Submits work asynchronously; ordering is preserved.
  public func async(execute work: @escaping @Sendable () -> Void) {
    queue.async(execute: work)
  }

  /// Submits work after a delay.
  public func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void) {
    queue.asyncAfter(deadline: deadline, execute: work)
  }

  /// Exposes the backing queue for advanced composition (use sparingly).
  public var underlyingQueue: DispatchQueue { queue }
}

// MARK: - Concurrent executor

/// Runs closures on a private concurrent `DispatchQueue` (unordered completion; use a group if you need a barrier).
public final class FKAsyncConcurrentExecutor: @unchecked Sendable {
  private let queue: DispatchQueue

  /// Creates an executor with a dedicated concurrent queue.
  ///
  /// - Parameters:
  ///   - label: Unique queue label.
  ///   - qos: QoS for the underlying queue.
  public init(label: String, qos: DispatchQoS = .default) {
    queue = FKAsyncQueues.concurrent(label: label, qos: qos)
  }

  /// Submits work asynchronously; tasks may run in parallel.
  public func async(execute work: @escaping @Sendable () -> Void) {
    queue.async(execute: work)
  }

  /// Submits work after a delay.
  public func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void) {
    queue.asyncAfter(deadline: deadline, execute: work)
  }

  /// Exposes the backing queue for barriers or `DispatchGroup` coordination.
  public var underlyingQueue: DispatchQueue { queue }
}
