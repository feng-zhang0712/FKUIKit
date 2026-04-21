import Foundation

/// Tracks active `FKBadgeController` instances (weak) for `hideAllBadges` / `restoreAllBadges`.
/// Thread-safe via `NSLock`; `Sendable` allows `static let shared` under strict concurrency (all state guarded by the lock).
final class FKBadgeRegistry: @unchecked Sendable {
  /// Shared registry instance.
  static let shared = FKBadgeRegistry()

  // Protects all mutable shared state below.
  private let lock = NSLock()
  // Weak table avoids retaining controllers and allows automatic cleanup on deallocation.
  private var controllers = NSHashTable<AnyObject>.weakObjects()
  // Global override used by batch hide/restore APIs.
  private var isGloballySuppressed = false

  private init() {}

  /// Registers a controller for global visibility broadcasts.
  ///
  /// - Parameter controller: Badge controller to include in registry snapshots.
  func register(_ controller: FKBadgeController) {
    lock.lock()
    controllers.add(controller)
    lock.unlock()
  }

  /// Unregisters a controller.
  ///
  /// - Parameter controller: Badge controller to remove.
  func unregister(_ controller: FKBadgeController) {
    lock.lock()
    controllers.remove(controller)
    lock.unlock()
  }

  /// Sets global suppression and refreshes all tracked badges.
  ///
  /// - Parameters:
  ///   - suppressed: `true` hides all badges, `false` restores per-badge rules.
  ///   - animated: Propagated to each controller refresh.
  func setGlobalSuppressed(_ suppressed: Bool, animated: Bool) {
    lock.lock()
    isGloballySuppressed = suppressed
    let snapshot = controllers.allObjects.compactMap { $0 as? FKBadgeController }
    lock.unlock()
    // Snapshot under lock, then refresh outside lock to avoid lock contention with UI work.
    snapshot.forEach { controller in
      Task { @MainActor in
        controller.refreshFromRegistry(animated: animated)
      }
    }
  }

  /// Current global suppression flag.
  var globalSuppressed: Bool {
    lock.lock()
    let v = isGloballySuppressed
    lock.unlock()
    return v
  }
}
