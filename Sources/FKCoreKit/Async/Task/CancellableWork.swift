import Foundation

// MARK: - Cancellable delayed work

/// Schedules a block on a dispatch queue after a delay; supports cancellation without retain cycles.
///
/// Hold a strong reference only while the delay is pending; call ``cancel()`` or drop the reference after `cancel()`.
public final class FKCancellableDelayedWork: FKAsyncCancellable, @unchecked Sendable {
  private var item: DispatchWorkItem?
  private let lock = NSLock()
  private let queue: DispatchQueue

  /// Creates a cancellable scheduler that dispatches on `queue`.
  ///
  /// - Parameter queue: Target queue for `asyncAfter` (default: global default QoS).
  public init(queue: DispatchQueue = FKAsyncQueues.global()) {
    self.queue = queue
  }

  /// Schedules `work` after `delay` seconds; cancels any prior pending work from this receiver.
  ///
  /// - Parameters:
  ///   - delay: Non-negative delay in seconds.
  ///   - work: Executed on `queue` when the deadline fires (unless cancelled).
  public func schedule(after delay: TimeInterval, execute work: @escaping @Sendable () -> Void) {
    let newItem = DispatchWorkItem(block: work)
    lock.lock()
    item?.cancel()
    item = newItem
    lock.unlock()
    queue.asyncAfter(deadline: .now() + max(0, delay), execute: newItem)
  }

  public func cancel() {
    lock.lock()
    item?.cancel()
    item = nil
    lock.unlock()
  }

  deinit {
    cancel()
  }
}
