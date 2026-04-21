import Foundation

// MARK: - Debouncer

/// Coalesces high-frequency callbacks (search, resize) into a single execution after idle time.
public final class FKDebouncer: FKAsyncDebouncing, @unchecked Sendable {
  private var pending: DispatchWorkItem?
  private let interval: TimeInterval
  private let queue: DispatchQueue
  private let lock = NSLock()

  /// Creates a debouncer.
  ///
  /// - Parameters:
  ///   - interval: Quiet period in seconds before `action` runs.
  ///   - queue: Queue used for the delayed execution (often `DispatchQueue.main` for UI).
  public init(interval: TimeInterval, queue: DispatchQueue = .main) {
    self.interval = interval
    self.queue = queue
  }

  public func signal(_ action: @escaping @Sendable () -> Void) {
    let work = DispatchWorkItem(block: action)
    lock.lock()
    pending?.cancel()
    pending = work
    lock.unlock()
    queue.asyncAfter(deadline: .now() + max(0, interval), execute: work)
  }

  public func cancelPending() {
    lock.lock()
    pending?.cancel()
    pending = nil
    lock.unlock()
  }

  deinit {
    cancelPending()
  }
}
