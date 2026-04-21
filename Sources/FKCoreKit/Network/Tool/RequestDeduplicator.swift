import Foundation

/// Tracks in-flight request keys to prevent duplicate execution.
///
/// This helper is used when request behavior is set to
/// `.idempotentDeduplicated`.
public final class FKRequestDeduplicator: @unchecked Sendable {
  /// Set of in-flight request keys.
  private var inflight: Set<String> = []
  /// Lock guarding concurrent set mutations.
  private let lock = NSLock()

  /// Creates deduplicator.
  public init() {}

  /// Registers request key if not in flight.
  ///
  /// - Parameter key: Stable request key.
  /// - Returns: `true` when request should proceed; `false` when duplicate.
  public func shouldProceed(key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    if inflight.contains(key) {
      return false
    }
    inflight.insert(key)
    return true
  }

  /// Marks request key as completed.
  ///
  /// - Parameter key: Stable request key.
  public func complete(key: String) {
    lock.lock()
    inflight.remove(key)
    lock.unlock()
  }
}
