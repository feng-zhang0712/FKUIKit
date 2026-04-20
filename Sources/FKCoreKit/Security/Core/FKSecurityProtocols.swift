import Foundation

// MARK: - Execution

/// A lightweight executor abstraction for async cryptographic work.
public protocol FKSecurityExecuting: Sendable {
  /// Runs work on a background executor and returns its result.
  func run<T>(_ work: @escaping () throws -> T) async throws -> T
}

// MARK: - Hash

/// Hashing capability for strings, data, and files.
public protocol FKHashing: Sendable {
  func hashString(_ string: String, algorithm: FKHashAlgorithm) async throws -> String
  func hashData(_ data: Data, algorithm: FKHashAlgorithm) async throws -> String
  func hashFile(at url: URL, algorithm: FKHashAlgorithm) async throws -> String

  func hashString(
    _ string: String,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  )

  func hashData(
    _ data: Data,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  )

  func hashFile(
    at url: URL,
    algorithm: FKHashAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  )
}

// MARK: - AES

/// Symmetric encryption capability (AES).
public protocol FKAESCrypting: Sendable {
  func encrypt(_ data: Data, using key: Data, iv: Data?, mode: FKAESMode) async throws -> Data
  func decrypt(_ data: Data, using key: Data, iv: Data?, mode: FKAESMode) async throws -> Data

  func encryptString(_ string: String, using key: Data, iv: Data?, mode: FKAESMode) async throws -> String
  func decryptString(_ base64Ciphertext: String, using key: Data, iv: Data?, mode: FKAESMode) async throws -> String

  func encryptFile(at inputURL: URL, to outputURL: URL, using key: Data, iv: Data?, mode: FKAESMode) async throws
  func decryptFile(at inputURL: URL, to outputURL: URL, using key: Data, iv: Data?, mode: FKAESMode) async throws

  func generateKey(length: Int) async throws -> Data
  func generateIV() async throws -> Data
}

// MARK: - RSA

/// Asymmetric cryptography capability (RSA).
public protocol FKRSACrypting: Sendable {
  func generateKeyPair(keySize: Int, tag: String, storeInKeychain: Bool) async throws -> FKRSAKeyPair

  func encrypt(_ data: Data, publicKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data
  func decrypt(_ data: Data, privateKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data

  func sign(_ data: Data, privateKey: SecKey, algorithm: FKRSAKindOfSignature) async throws -> Data
  func verify(_ signature: Data, data: Data, publicKey: SecKey, algorithm: FKRSAKindOfSignature) async throws -> Bool

  func exportPublicKeySPKIDER(_ publicKey: SecKey) async throws -> Data
  func exportPrivateKeyPKCS8DER(_ privateKey: SecKey) async throws -> Data

  func importPublicKey(fromDER data: Data, isSPKI: Bool) async throws -> SecKey
  func importPrivateKey(fromDER data: Data, isPKCS8: Bool) async throws -> SecKey

  func publicKey(from privateKey: SecKey) async throws -> SecKey
}

// MARK: - Encoding

/// Data encoding and transformation utilities.
public protocol FKSecurityCoding: Sendable {
  func base64Encode(_ data: Data) -> String
  func base64Decode(_ string: String) throws -> Data

  func urlEncode(_ string: String) -> String
  func urlDecode(_ string: String) -> String

  func hexString(from data: Data, uppercase: Bool) -> String
  func data(fromHex hex: String) throws -> Data
}

// MARK: - Signature

/// Message authentication and parameter signing.
public protocol FKSecuritySigning: Sendable {
  func hmac(_ data: Data, key: Data, algorithm: FKHMACAlgorithm) async throws -> Data
  func hmacHex(_ data: Data, key: Data, algorithm: FKHMACAlgorithm) async throws -> String

  /// Creates a stable signature string for request parameters.
  func signParameters(
    _ parameters: [String: Any],
    secret: String,
    algorithm: FKHMACAlgorithm
  ) async throws -> String

  /// Verifies a signature of request parameters.
  func verifyParameters(
    _ parameters: [String: Any],
    secret: String,
    signatureHex: String,
    algorithm: FKHMACAlgorithm
  ) async throws -> Bool
}

// MARK: - Utilities

/// Security-related utilities for randomness, masking, and basic integrity checks.
public protocol FKSecurityUtilizing: Sendable {
  func randomBytes(count: Int) async throws -> Data
  func randomString(length: Int, alphabet: String) async throws -> String

  func maskPhone(_ value: String) -> String
  func maskIDCard(_ value: String) -> String
  func maskEmail(_ value: String) -> String

  func isDebuggerAttached() -> Bool
  func hasSuspiciousEnvironment() -> Bool

  func snapshotExecutableHash(algorithm: FKHashAlgorithm) async throws -> String
  func verifyExecutableHashSnapshot(_ expected: String, algorithm: FKHashAlgorithm) async throws -> Bool

  func secureWipe(_ data: inout Data)
  func secureWipeFile(at url: URL, passes: Int) async throws
}

// MARK: - Key Storage

/// Key storage abstraction for sensitive key material (Keychain-backed by default).
public protocol FKSecurityKeyStoring: Sendable {
  func setKey(_ data: Data, forKey key: String, accessibility: CFString) throws
  func key(forKey key: String) throws -> Data
  func removeKey(forKey key: String) throws
  func exists(key: String) -> Bool
}

