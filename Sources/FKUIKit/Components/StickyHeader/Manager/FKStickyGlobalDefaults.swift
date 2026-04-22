import Foundation

enum FKStickyGlobalDefaults {
  private static let lock = NSLock()
  nonisolated(unsafe) private static var storedConfiguration = FKStickyConfiguration.default

  static var configuration: FKStickyConfiguration {
    get {
      lock.lock()
      defer { lock.unlock() }
      return storedConfiguration
    }
    set {
      lock.lock()
      storedConfiguration = newValue
      lock.unlock()
    }
  }
}
