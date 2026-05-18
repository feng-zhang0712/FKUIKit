import Foundation

/// UserDefaults-backed implementation of ``FKAudioPlayHistoryStore``.
public final class FKAudioUserDefaultsPlayHistoryStore: FKAudioPlayHistoryStore, @unchecked Sendable {

  private let defaults: UserDefaults
  private let key: String
  private let lock = NSLock()

  public init(defaults: UserDefaults = .standard, key: String = "FKAudioPlayHistory") {
    self.defaults = defaults
    self.key = key
  }

  public func recordPlayed(itemID: String, at date: Date) {
    lock.lock()
    defer { lock.unlock() }
    var entries = loadEntries()
    entries.removeAll { $0.id == itemID }
    entries.insert(HistoryEntry(id: itemID, date: date), at: 0)
    if entries.count > 200 {
      entries = Array(entries.prefix(200))
    }
    save(entries)
  }

  public func recentItemIDs(limit: Int) -> [String] {
    lock.lock()
    defer { lock.unlock() }
    return Array(loadEntries().prefix(limit).map(\.id))
  }

  private struct HistoryEntry: Codable {
    let id: String
    let date: Date
  }

  private func loadEntries() -> [HistoryEntry] {
    guard let data = defaults.data(forKey: key) else { return [] }
    return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
  }

  private func save(_ entries: [HistoryEntry]) {
    guard let data = try? JSONEncoder().encode(entries) else { return }
    defaults.set(data, forKey: key)
  }
}
