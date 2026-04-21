import Foundation

// MARK: - Main queue execution

/// Abstraction for scheduling work on the main dispatch queue (inject in tests with a mock).
public protocol FKAsyncMainExecuting: AnyObject, Sendable {
  /// Posts `work` to execute asynchronously on the main queue.
  func asyncOnMain(_ work: @escaping @Sendable () -> Void)

  /// Runs `work` immediately if the caller is already on the main thread; otherwise posts asynchronously to main.
  func runOnMain(_ work: @escaping @Sendable () -> Void)
}

// MARK: - Background execution

/// Abstraction for scheduling work on a background (non-main) queue.
public protocol FKAsyncBackgroundExecuting: AnyObject, Sendable {
  /// Submits `work` to a global concurrent queue with the given QoS.
  func asyncGlobal(qos: DispatchQoS, execute work: @escaping @Sendable () -> Void)
}

// MARK: - Cancellable work

/// Token that cancels a single scheduled or repeating asynchronous unit of work.
public protocol FKAsyncCancellable: AnyObject, Sendable {
  /// Cancels the work if it has not started; no-op if already finished or cancelled.
  func cancel()
}

// MARK: - Debounce / throttle

/// Merges rapid signals into one execution after a quiet period.
public protocol FKAsyncDebouncing: AnyObject, Sendable {
  /// Schedules `action` to run after `interval` without further `signal` calls; each call resets the timer.
  func signal(_ action: @escaping @Sendable () -> Void)

  /// Cancels any pending debounced execution.
  func cancelPending()
}

/// Limits how often `action` may run (leading-edge rate limit by default).
public protocol FKAsyncThrottling: AnyObject, Sendable {
  /// Invokes `action` only if the minimum interval since the last invocation has elapsed.
  func throttle(_ action: @escaping @Sendable () -> Void)
}
