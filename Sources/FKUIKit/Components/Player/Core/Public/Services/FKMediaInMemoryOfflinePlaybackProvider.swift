import Foundation

/// Thread-safe in-memory registry for offline download identifiers.
public final class FKMediaInMemoryOfflinePlaybackProvider: FKMediaOfflinePlaybackProviding, @unchecked Sendable {

  private var storage: [String: URL] = [:]
  private let lock = NSLock()

  public init() {}

  public func playbackURL(forDownloadIdentifier identifier: String) -> URL? {
    lock.lock()
    defer { lock.unlock() }
    return storage[identifier]
  }

  public func register(downloadIdentifier: String, localURL: URL) {
    lock.lock()
    defer { lock.unlock() }
    storage[downloadIdentifier] = localURL
  }

  public func unregister(downloadIdentifier: String) {
    lock.lock()
    defer { lock.unlock() }
    storage.removeValue(forKey: downloadIdentifier)
  }
}
