import Foundation

// MARK: - Throttler

/// Limits execution rate (e.g. scroll callbacks, log flood): invokes `action` at most once per `interval`.
///
/// The first call in a cool-down window runs immediately; subsequent calls inside the window are dropped.
public final class FKThrottler: FKAsyncThrottling, @unchecked Sendable {
  private let interval: TimeInterval
  private let queue: DispatchQueue
  private var lastInvocation: TimeInterval?
  private let lock = NSLock()

  /// Creates a throttler with a minimum spacing between successful invocations.
  ///
  /// - Parameters:
  ///   - interval: Minimum seconds between two executed actions.
  ///   - queue: Queue on which `action` is submitted when allowed (default: main).
  public init(interval: TimeInterval, queue: DispatchQueue = .main) {
    self.interval = interval
    self.queue = queue
  }

  public func throttle(_ action: @escaping @Sendable () -> Void) {
    lock.lock()
    let now = Date().timeIntervalSince1970
    if let last = lastInvocation, now - last < interval {
      lock.unlock()
      return
    }
    lastInvocation = now
    lock.unlock()
    queue.async(execute: action)
  }

  /// Resets the last-invocation time so the next ``throttle`` can fire immediately.
  public func reset() {
    lock.lock()
    lastInvocation = nil
    lock.unlock()
  }
}
