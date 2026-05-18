import Foundation

/// Persists offline download identifier → local URL mappings.
public protocol FKMediaOfflineDownloadRegistry: AnyObject, Sendable {
  func register(downloadIdentifier: String, localURL: URL)
  func unregister(downloadIdentifier: String)
  func localURL(for downloadIdentifier: String) -> URL?
  func allDownloadIdentifiers() -> [String]
}

/// UserDefaults-backed offline registry.
public final class FKMediaUserDefaultsOfflineDownloadRegistry: FKMediaOfflineDownloadRegistry, @unchecked Sendable {

  private let defaults: UserDefaults
  private let key: String
  private let lock = NSLock()

  public init(defaults: UserDefaults = .standard, key: String = "FKMediaOfflineDownloads") {
    self.defaults = defaults
    self.key = key
  }

  public func register(downloadIdentifier: String, localURL: URL) {
    lock.lock()
    defer { lock.unlock() }
    var map = storage()
    map[downloadIdentifier] = localURL.absoluteString
    save(map)
  }

  public func unregister(downloadIdentifier: String) {
    lock.lock()
    defer { lock.unlock() }
    var map = storage()
    map.removeValue(forKey: downloadIdentifier)
    save(map)
  }

  public func localURL(for downloadIdentifier: String) -> URL? {
    lock.lock()
    defer { lock.unlock() }
    guard let value = storage()[downloadIdentifier] else { return nil }
    return URL(string: value)
  }

  public func allDownloadIdentifiers() -> [String] {
    lock.lock()
    defer { lock.unlock() }
    return Array(storage().keys)
  }

  private func storage() -> [String: String] {
    defaults.dictionary(forKey: key) as? [String: String] ?? [:]
  }

  private func save(_ map: [String: String]) {
    defaults.set(map, forKey: key)
  }
}
