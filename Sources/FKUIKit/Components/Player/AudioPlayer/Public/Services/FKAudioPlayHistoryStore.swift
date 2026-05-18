import Foundation

/// Optional play-history persistence (Phase 3 enhancement).
public protocol FKAudioPlayHistoryStore: Sendable {
  func recordPlayed(itemID: String, at date: Date)
  func recentItemIDs(limit: Int) -> [String]
}

/// In-memory play history for demos and tests.
public final class FKAudioInMemoryPlayHistoryStore: FKAudioPlayHistoryStore, @unchecked Sendable {

  private var entries: [(id: String, date: Date)] = []
  private let lock = NSLock()

  public init() {}

  public func recordPlayed(itemID: String, at date: Date) {
    lock.lock()
    defer { lock.unlock() }
    entries.removeAll { $0.id == itemID }
    entries.insert((itemID, date), at: 0)
    if entries.count > 200 {
      entries.removeLast(entries.count - 200)
    }
  }

  public func recentItemIDs(limit: Int) -> [String] {
    lock.lock()
    defer { lock.unlock() }
    return Array(entries.prefix(limit).map(\.id))
  }
}
