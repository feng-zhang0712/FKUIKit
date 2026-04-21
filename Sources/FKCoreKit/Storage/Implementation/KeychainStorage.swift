import Foundation
import Security

// MARK: - FKKeychainStorage

/// Stores secrets in the Keychain as generic-password items (service + account).
///
/// **When to use:** access tokens, refresh tokens, passwords. Payload is still JSON (`ExpiringRecord` + value);
/// confidentiality comes from the Keychain, not extra app-level encryption.
///
/// **Service string:** all items share `service`; the logical `key` maps to `kSecAttrAccount`.
///
/// **Accessibility:** items use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (see ``setKeychainData(_:service:account:)``).
///
/// **Thread safety:** serial queue with `.userInitiated` QoS.
public final class FKKeychainStorage: FKCodableStorage, @unchecked Sendable {
  /// `kSecAttrService` for all items created by this instance.
  private let service: String

  private let queue = DispatchQueue(label: "com.fkkit.storage.keychain", qos: .userInitiated)

  /// Creates Keychain-backed storage scoped to one service identifier.
  ///
  /// - Parameter service: Unique string (commonly bundle id + suffix). Separate services isolate credentials.
  public init(service: String) {
    self.service = service
  }

  /// Encodes and stores data under `kSecAttrAccount` = `key` for this instance’s `service`.
  public func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) throws {
    try queue.sync {
      let payload = try StorageCodec.encode(value)
      let now = Date().timeIntervalSince1970
      let expiresAt = ttl.map { now + $0 }
      let record = ExpiringRecord(data: payload, expiresAt: expiresAt)
      let data = try StorageCodec.encode(record)
      try Self.setKeychainData(data, service: service, account: key)
    }
  }

  /// Loads and decodes one item; deletes expired items from Keychain before throwing ``FKStorageError/notFound``.
  public func value<Value: Codable & Sendable>(key: String, as type: Value.Type) throws -> Value {
    try queue.sync {
      guard let data = Self.copyKeychainData(service: service, account: key) else {
        throw FKStorageError.notFound
      }
      let record = try StorageCodec.decode(ExpiringRecord.self, from: data)
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        try? Self.deleteKeychain(service: service, account: key)
        throw FKStorageError.notFound
      }
      do {
        return try StorageCodec.decode(type, from: record.data)
      } catch {
        throw FKStorageError.decodingFailed(underlying: error)
      }
    }
  }

  /// Deletes the generic-password item for `service` + `key`.
  public func remove(key: String) throws {
    try queue.sync {
      try Self.deleteKeychain(service: service, account: key)
    }
  }

  /// `true` when a non-expired record is present (expired rows are removed).
  public func exists(key: String) -> Bool {
    queue.sync {
      guard let data = Self.copyKeychainData(service: service, account: key) else { return false }
      guard let record = try? StorageCodec.decode(ExpiringRecord.self, from: data) else { return false }
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        try? Self.deleteKeychain(service: service, account: key)
        return false
      }
      return true
    }
  }

  /// Deletes **all** generic-password items matching `service` (entire FKStorage scope for this instance).
  public func removeAll() throws {
    try queue.sync {
      let status = SecItemDelete([
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
      ] as CFDictionary)
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw FKStorageError.keychainFailed(status: status)
      }
    }
  }

  /// All `kSecAttrAccount` strings for this `service`.
  public func allKeys() throws -> [String] {
    try queue.sync {
      try Self.listAccounts(service: service)
    }
  }

  /// Iterates accounts and deletes expired TTL entries.
  public func purgeExpired() throws {
    try queue.sync {
      let keys = try Self.listAccounts(service: service)
      let now = Date().timeIntervalSince1970
      for account in keys {
        guard let data = Self.copyKeychainData(service: service, account: account) else { continue }
        guard let record = try? StorageCodec.decode(ExpiringRecord.self, from: data) else { continue }
        if record.isExpired(now: now) {
          try? Self.deleteKeychain(service: service, account: account)
        }
      }
    }
  }

  // MARK: - Keychain helpers

  /// Replaces any existing item for `service` + `account`, then adds bytes as `kSecValueData`.
  private static func setKeychainData(_ data: Data, service: String, account: String) throws {
    try deleteKeychain(service: service, account: account)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw FKStorageError.keychainFailed(status: status)
    }
  }

  /// Returns raw secret bytes for one account, or `nil` if not found.
  private static func copyKeychainData(service: String, account: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return data
  }

  /// Deletes one generic-password item; ignores `errSecItemNotFound`.
  private static func deleteKeychain(service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw FKStorageError.keychainFailed(status: status)
    }
  }

  /// Lists `kSecAttrAccount` for every generic-password with this `service` (single or multiple matches).
  private static func listAccounts(service: String) throws -> [String] {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecReturnAttributes as String: true,
      kSecMatchLimit as String: kSecMatchLimitAll,
    ]
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status != errSecItemNotFound else { return [] }
    guard status == errSecSuccess else {
      throw FKStorageError.keychainFailed(status: status)
    }
    // One item returns a dictionary; many items bridge to an array of dictionaries.
    if let dict = result as? [String: Any] {
      if let account = dict[kSecAttrAccount as String] as? String {
        return [account]
      }
    }
    if let array = result as? [Any] {
      return array.compactMap { item in
        (item as? [String: Any])?[kSecAttrAccount as String] as? String
      }
    }
    return []
  }
}
