import Foundation

// MARK: - FKUserDefaultsStorage

/// Persists small preferences using `UserDefaults`, with JSON encoding and optional TTL.
///
/// **When to use:** feature flags, last-sync timestamps, UI settings. **Avoid** large blobs—prefer ``FKFileStorage``.
///
/// **Key prefix:** every logical `key` is stored under `keyPrefix + key` so ``removeAll()``, ``allKeys()``,
/// and ``purgeExpired()`` only touch FKStorage-owned entries, not unrelated defaults in the same suite.
///
/// **Thread safety:** all operations run on an internal serial queue.
public final class FKUserDefaultsStorage: FKCodableStorage, @unchecked Sendable {
  /// Backing `UserDefaults` (standard or app-group suite).
  private let defaults: UserDefaults

  /// String prepended to each logical key in the plist (default `fk.storage.`).
  private let keyPrefix: String

  /// Serializes access; QoS `.utility` matches non-urgent preference I/O.
  private let queue = DispatchQueue(label: "com.fkkit.storage.userdefaults", qos: .utility)

  /// Creates storage for a suite with an optional key prefix.
  ///
  /// - Parameters:
  ///   - suiteName: Pass an App Group or custom suite name; `nil` uses `UserDefaults.standard`.
  ///   - keyPrefix: Prefix for physical keys; must be unique per feature area if sharing a suite.
  /// - Precondition: If `suiteName` is invalid, the initializer traps with `fatalError` (validate in app config).
  public init(suiteName: String? = nil, keyPrefix: String = "fk.storage.") {
    self.keyPrefix = keyPrefix
    if let suiteName {
      guard let d = UserDefaults(suiteName: suiteName) else {
        fatalError("FKUserDefaultsStorage: invalid suite \(suiteName)")
      }
      defaults = d
    } else {
      defaults = .standard
    }
  }

  /// Physical key written to `UserDefaults`.
  private func namespaced(_ key: String) -> String {
    keyPrefix + key
  }

  /// Strips the prefix from a full key, if it belongs to this instance.
  private func logicalKey(from namespaced: String) -> String? {
    guard namespaced.hasPrefix(keyPrefix) else { return nil }
    return String(namespaced.dropFirst(keyPrefix.count))
  }

  /// Encodes `value`, wraps optional TTL, writes `Data` to `UserDefaults` under the prefixed key.
  public func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) throws {
    try queue.sync {
      let payload = try StorageCodec.encode(value)
      let now = Date().timeIntervalSince1970
      let expiresAt = ttl.map { now + $0 }
      let record = ExpiringRecord(data: payload, expiresAt: expiresAt)
      let data = try StorageCodec.encode(record)
      defaults.set(data, forKey: namespaced(key))
    }
  }

  /// Reads `Data`, unwraps ``ExpiringRecord``, rejects expired rows, then decodes the payload.
  public func value<Value: Codable & Sendable>(key: String, as type: Value.Type) throws -> Value {
    try queue.sync {
      let nk = namespaced(key)
      guard let blob = defaults.data(forKey: nk) else {
        throw FKStorageError.notFound
      }
      let record = try StorageCodec.decode(ExpiringRecord.self, from: blob)
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        defaults.removeObject(forKey: nk)
        throw FKStorageError.notFound
      }
      do {
        return try StorageCodec.decode(type, from: record.data)
      } catch {
        throw FKStorageError.decodingFailed(underlying: error)
      }
    }
  }

  /// Removes the namespaced key if present.
  public func remove(key: String) throws {
    queue.sync {
      defaults.removeObject(forKey: namespaced(key))
    }
  }

  /// Returns `true` only when a decodable, non-expired record exists.
  public func exists(key: String) -> Bool {
    queue.sync {
      let nk = namespaced(key)
      guard defaults.data(forKey: nk) != nil else { return false }
      guard let blob = defaults.data(forKey: nk) else { return false }
      guard let record = try? StorageCodec.decode(ExpiringRecord.self, from: blob) else { return false }
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        defaults.removeObject(forKey: nk)
        return false
      }
      return true
    }
  }

  /// Deletes every key in this suite that starts with ``keyPrefix``.
  public func removeAll() throws {
    queue.sync {
      for full in defaults.dictionaryRepresentation().keys {
        guard logicalKey(from: full) != nil else { continue }
        defaults.removeObject(forKey: full)
      }
    }
  }

  /// Logical keys (prefix stripped), sorted.
  public func allKeys() throws -> [String] {
    queue.sync {
      defaults.dictionaryRepresentation().keys.compactMap { logicalKey(from: $0) }.sorted()
    }
  }

  /// Scans prefixed keys and removes records whose TTL has passed.
  public func purgeExpired() throws {
    queue.sync {
      let now = Date().timeIntervalSince1970
      for full in defaults.dictionaryRepresentation().keys {
        guard logicalKey(from: full) != nil else { continue }
        guard let blob = defaults.data(forKey: full) else { continue }
        guard let record = try? StorageCodec.decode(ExpiringRecord.self, from: blob) else { continue }
        if record.isExpired(now: now) {
          defaults.removeObject(forKey: full)
        }
      }
    }
  }
}
