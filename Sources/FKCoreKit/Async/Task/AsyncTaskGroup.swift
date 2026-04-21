import Foundation

// MARK: - DispatchGroup wrapper

/// Thin, thread-safe wrapper around `DispatchGroup` for coordinating multiple asynchronous GCD tasks.
///
/// Balance every ``enter()`` with exactly one ``leave()`` on all paths (including error paths).
public final class FKAsyncTaskGroup: @unchecked Sendable {
  private let group = DispatchGroup()

  /// Creates an empty task group wrapper.
  public init() {}

  /// Marks the start of an asynchronous task tracked by the group.
  public func enter() {
    group.enter()
  }

  /// Marks the end of a task previously started with ``enter()``.
  public func leave() {
    group.leave()
  }

  /// Schedules `work` when all tracked tasks have finished.
  ///
  /// - Parameters:
  ///   - queue: Queue on which `work` runs (use `DispatchQueue.main` for UI).
  ///   - work: Called when the group count reaches zero.
  public func notify(queue: DispatchQueue, execute work: @escaping @Sendable () -> Void) {
    group.notify(queue: queue, execute: work)
  }

  /// Synchronously waits for the group (blocks the caller). Prefer ``notify(queue:execute:)`` on the main thread.
  ///
  /// - Parameter timeout: Maximum time to wait; pass `.distantFuture` to wait indefinitely.
  /// - Returns: The result of waiting (timeout vs success).
  public func wait(timeout: DispatchTime = .distantFuture) -> DispatchTimeoutResult {
    group.wait(timeout: timeout)
  }
}
