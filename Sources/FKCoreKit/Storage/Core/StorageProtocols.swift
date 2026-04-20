import Foundation

// MARK: - FKStorage protocols

/// Shared contract for FKStorage backends that support bulk operations, existence checks, and TTL cleanup.
///
/// Implementations wrap persistence (UserDefaults, Keychain, files, or memory) behind a uniform API.
/// **Thread safety:** every concrete backend serializes access internally; synchronous methods may block
/// on a private queue. Prefer the `async` overloads in `StorageAsync.swift` when calling from the main thread
/// and you want the cooperative pool to schedule the work.
///
/// **Key strings:** pass logical keys (for example ``FKStorageKey/fullKey``). Backends may add their own
/// prefix or hashing; see each type’s documentation.
public protocol FKStorageBackend: AnyObject, Sendable {
  /// Removes every entry owned by this storage instance (same scope as ``allKeys()``).
  ///
  /// - Note: For ``FKUserDefaultsStorage``, only keys matching the instance’s prefix are removed—not the entire suite.
  func removeAll() throws

  /// Returns logical key strings currently present and non-expired (where TTL applies).
  ///
  /// - Returns: Sorted or unsorted keys depending on the implementation; never includes expired TTL entries that were purged on read.
  func allKeys() throws -> [String]

  /// Whether a readable, non-expired value exists for `key`.
  ///
  /// - Parameter key: Logical storage key.
  /// - Returns: `false` if missing, corrupt, or expired (implementations may delete expired data as a side effect).
  func exists(key: String) -> Bool

  /// Removes the value for `key` if it exists.
  ///
  /// - Parameter key: Logical storage key.
  func remove(key: String) throws

  /// Deletes entries whose TTL has passed, where the backend stores expiry metadata.
  ///
  /// - Note: Safe to call periodically (for example on app launch). No-op on backends that do not use TTL.
  func purgeExpired() throws
}

/// Typed storage for values that are `Codable` and `Sendable`, built on JSON encoding via ``StorageCodec``.
///
/// Use for user preferences, cached DTOs, or secrets (with ``FKKeychainStorage``). Values are encoded to
/// `Data`, optionally wrapped in ``ExpiringRecord`` when `ttl` is set.
public protocol FKCodableStorage: FKStorageBackend {
  /// Encodes and stores `value` under `key`, optionally expiring after `ttl` seconds from the call time.
  ///
  /// - Parameters:
  ///   - value: Must encode with `JSONEncoder` (shared rules in ``StorageCodec``).
  ///   - key: Logical key string.
  ///   - ttl: Lifetime in seconds; pass `nil` to keep until overwritten or removed.
  /// - Throws: ``FKStorageError/encodingFailed`` if encoding fails.
  func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) throws

  /// Reads and decodes the stored value.
  ///
  /// - Parameters:
  ///   - key: Logical key.
  ///   - type: Expected Swift type; must match what was stored.
  /// - Returns: Decoded value.
  /// - Throws: ``FKStorageError/notFound`` if missing or expired; ``FKStorageError/decodingFailed`` if bytes cannot decode into `type`.
  func value<Value: Codable & Sendable>(key: String, as type: Value.Type) throws -> Value
}

public extension FKCodableStorage {
  /// Persists `value` under `key` with no expiration.
  ///
  /// - Parameters:
  ///   - value: Value to encode and store.
  ///   - key: Logical key.
  func set<Value: Codable & Sendable>(_ value: Value, key: String) throws {
    try set(value, key: key, ttl: nil)
  }
}
