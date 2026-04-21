import Foundation

// MARK: - FKMemoryStorage

/// In-process dictionary cache with optional TTL; **not** persisted after app termination.
///
/// **When to use:** request de-duplication, session-only UI state, hot paths where disk/Keychain is too slow.
///
/// **Thread safety:** `NSLock` around the dictionary; avoid holding the lock across slow work outside this type.
public final class FKMemoryStorage: FKCodableStorage, @unchecked Sendable {
  /// Holds JSON payload and optional expiry (same time base as other backends).
  private struct Entry: Sendable {
    var data: Data
    var expiresAt: TimeInterval?
  }

  /// Keyed by logical storage key.
  private var storage: [String: Entry] = [:]

  /// Protects `storage` across threads.
  private let lock = NSLock()

  /// Creates an empty memory store.
  public init() {}

  /// Stores encoded bytes under `key`, replacing any prior entry.
  public func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) throws {
    let payload = try StorageCodec.encode(value)
    let now = Date().timeIntervalSince1970
    let expiresAt = ttl.map { now + $0 }
    lock.lock()
    storage[key] = Entry(data: payload, expiresAt: expiresAt)
    lock.unlock()
  }

  /// Returns decoded value or throws if missing or TTL elapsed (entry removed).
  public func value<Value: Codable & Sendable>(key: String, as type: Value.Type) throws -> Value {
    lock.lock()
    defer { lock.unlock() }
    guard let entry = storage[key] else {
      throw FKStorageError.notFound
    }
    let now = Date().timeIntervalSince1970
    if let exp = entry.expiresAt, now >= exp {
      storage.removeValue(forKey: key)
      throw FKStorageError.notFound
    }
    do {
      return try StorageCodec.decode(type, from: entry.data)
    } catch {
      throw FKStorageError.decodingFailed(underlying: error)
    }
  }

  /// Removes one key from the dictionary.
  public func remove(key: String) throws {
    lock.lock()
    storage.removeValue(forKey: key)
    lock.unlock()
  }

  /// `true` when a non-expired entry exists.
  public func exists(key: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard let entry = storage[key] else { return false }
    let now = Date().timeIntervalSince1970
    if let exp = entry.expiresAt, now >= exp {
      storage.removeValue(forKey: key)
      return false
    }
    return true
  }

  /// Clears every in-memory entry.
  public func removeAll() throws {
    lock.lock()
    storage.removeAll()
    lock.unlock()
  }

  /// Non-expired keys, sorted (drops expired while iterating).
  public func allKeys() throws -> [String] {
    lock.lock()
    defer { lock.unlock() }
    let now = Date().timeIntervalSince1970
    var keys: [String] = []
    for (key, entry) in storage {
      if let exp = entry.expiresAt, now >= exp {
        storage.removeValue(forKey: key)
        continue
      }
      keys.append(key)
    }
    return keys.sorted()
  }

  /// Removes all entries whose TTL has passed.
  public func purgeExpired() throws {
    lock.lock()
    defer { lock.unlock() }
    let now = Date().timeIntervalSince1970
    for (key, entry) in storage {
      if let exp = entry.expiresAt, now >= exp {
        storage.removeValue(forKey: key)
      }
    }
  }
}
