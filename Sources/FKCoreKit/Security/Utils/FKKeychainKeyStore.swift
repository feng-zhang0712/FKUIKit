import Foundation
import Security

/// Keychain-backed key store for raw key bytes.
public final class FKKeychainKeyStore: FKSecurityKeyStoring, @unchecked Sendable {
  private let service: String
  private let queue = DispatchQueue(label: "com.fkkit.security.keystore", qos: .userInitiated)

  /// Creates a Keychain store scoped to one service identifier.
  public init(service: String) {
    self.service = service
  }

  public func setKey(_ data: Data, forKey key: String, accessibility: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) throws {
    try queue.sync {
      try Self.delete(service: service, account: key)
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: accessibility,
      ]
      let status = SecItemAdd(query as CFDictionary, nil)
      guard status == errSecSuccess else {
        throw FKSecurityError.securityFailed(status: status, message: "SecItemAdd failed.")
      }
    }
  }

  public func key(forKey key: String) throws -> Data {
    try queue.sync {
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
      ]
      var item: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &item)
      guard status == errSecSuccess, let data = item as? Data else {
        throw FKSecurityError.keyNotFound(key)
      }
      return data
    }
  }

  public func removeKey(forKey key: String) throws {
    try queue.sync {
      try Self.delete(service: service, account: key)
    }
  }

  public func exists(key: String) -> Bool {
    (try? self.key(forKey: key)) != nil
  }

  private static func delete(service: String, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw FKSecurityError.securityFailed(status: status, message: "SecItemDelete failed.")
    }
  }
}

