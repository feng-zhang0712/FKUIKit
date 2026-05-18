import Foundation

/// Persists and restores last playback positions per media item identifier.
public protocol FKMediaResumeStore: Sendable {
  func position(for itemID: String) -> TimeInterval?
  func setPosition(_ position: TimeInterval, for itemID: String)
  func removePosition(for itemID: String)
}

/// UserDefaults-backed resume position store.
public final class FKMediaUserDefaultsResumeStore: FKMediaResumeStore, @unchecked Sendable {

  private let defaults: UserDefaults
  private let keyPrefix: String

  public init(defaults: UserDefaults = .standard, keyPrefix: String = "FKMediaResume.") {
    self.defaults = defaults
    self.keyPrefix = keyPrefix
  }

  public func position(for itemID: String) -> TimeInterval? {
    let key = keyPrefix + itemID
    guard defaults.object(forKey: key) != nil else { return nil }
    return defaults.double(forKey: key)
  }

  public func setPosition(_ position: TimeInterval, for itemID: String) {
    defaults.set(position, forKey: keyPrefix + itemID)
  }

  public func removePosition(for itemID: String) {
    defaults.removeObject(forKey: keyPrefix + itemID)
  }
}

/// In-memory resume store useful for tests and ephemeral sessions.
public final class FKMediaInMemoryResumeStore: FKMediaResumeStore, @unchecked Sendable {

  private var storage: [String: TimeInterval] = [:]
  private let lock = NSLock()

  public init() {}

  public func position(for itemID: String) -> TimeInterval? {
    lock.lock()
    defer { lock.unlock() }
    return storage[itemID]
  }

  public func setPosition(_ position: TimeInterval, for itemID: String) {
    lock.lock()
    defer { lock.unlock() }
    storage[itemID] = position
  }

  public func removePosition(for itemID: String) {
    lock.lock()
    defer { lock.unlock() }
    storage.removeValue(forKey: itemID)
  }
}
