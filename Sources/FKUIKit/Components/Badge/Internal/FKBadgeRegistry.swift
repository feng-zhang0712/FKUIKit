import Foundation

/// Tracks active `FKBadgeController` instances (weak) for `FKBadge.hideAllBadges` / `FKBadge.restoreAllBadges`.
/// Thread-safe via `NSLock`; `Sendable` allows `static let shared` under strict concurrency (all state guarded by the lock).
final class FKBadgeRegistry: @unchecked Sendable {
  static let shared = FKBadgeRegistry()

  private let lock = NSLock()
  private var controllers = NSHashTable<AnyObject>.weakObjects()
  private var isGloballySuppressed = false

  private init() {}

  func register(_ controller: FKBadgeController) {
    lock.lock()
    controllers.add(controller)
    lock.unlock()
  }

  func unregister(_ controller: FKBadgeController) {
    lock.lock()
    controllers.remove(controller)
    lock.unlock()
  }

  func setGlobalSuppressed(_ suppressed: Bool, animated: Bool) {
    lock.lock()
    isGloballySuppressed = suppressed
    let snapshot = controllers.allObjects.compactMap { $0 as? FKBadgeController }
    lock.unlock()
    snapshot.forEach { controller in
      Task { @MainActor in
        controller.refreshFromRegistry(animated: animated)
      }
    }
  }

  var globalSuppressed: Bool {
    lock.lock()
    let v = isGloballySuppressed
    lock.unlock()
    return v
  }
}
