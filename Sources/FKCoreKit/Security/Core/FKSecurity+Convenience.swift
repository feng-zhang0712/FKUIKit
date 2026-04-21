import Foundation
@preconcurrency import Security

// MARK: - One-liner convenience APIs

extension FKSecurity {
  /// Hashes a string and returns a lowercase HEX digest.
  public func hash(_ algorithm: FKHashAlgorithm, string: String) async throws -> String {
    try await hash.hashString(string, algorithm: algorithm)
  }

  /// Hashes data and returns a lowercase HEX digest.
  public func hash(_ algorithm: FKHashAlgorithm, data: Data) async throws -> String {
    try await hash.hashData(data, algorithm: algorithm)
  }

  /// AES-encrypts a string and returns Base64 ciphertext.
  public func aesEncrypt(_ string: String, key: Data, iv: Data?, mode: FKAESMode) async throws -> String {
    try await aes.encryptString(string, using: key, iv: iv, mode: mode)
  }

  /// AES-decrypts a Base64 ciphertext string and returns plaintext.
  public func aesDecrypt(_ base64Ciphertext: String, key: Data, iv: Data?, mode: FKAESMode) async throws -> String {
    try await aes.decryptString(base64Ciphertext, using: key, iv: iv, mode: mode)
  }

  /// RSA-encrypts data with a public key.
  public func rsaEncrypt(_ data: Data, publicKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data {
    try await rsa.encrypt(data, publicKey: publicKey, algorithm: algorithm)
  }

  /// RSA-decrypts data with a private key.
  public func rsaDecrypt(_ data: Data, privateKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data {
    try await rsa.decrypt(data, privateKey: privateKey, algorithm: algorithm)
  }

  /// HMAC-signs parameters into a HEX string.
  public func hmacSignParams(_ parameters: [String: Any], secret: String, algorithm: FKHMACAlgorithm) async throws -> String {
    try await sign.signParameters(parameters, secret: secret, algorithm: algorithm)
  }
}

// MARK: - Closure overloads

extension FKSecurity {
  public func hash(_ algorithm: FKHashAlgorithm, string: String, completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void) {
    hash.hashString(string, algorithm: algorithm, completion: completion)
  }

  public func aesEncrypt(_ string: String, key: Data, iv: Data?, mode: FKAESMode, completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void) {
    Task {
      do { completion(.success(try await aesEncrypt(string, key: key, iv: iv, mode: mode))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func aesDecrypt(_ base64Ciphertext: String, key: Data, iv: Data?, mode: FKAESMode, completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void) {
    Task {
      do { completion(.success(try await aesDecrypt(base64Ciphertext, key: key, iv: iv, mode: mode))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func rsaEncrypt(_ data: Data, publicKey: SecKey, algorithm: FKRSAEncryptionAlgorithm, completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void) {
    Task {
      do { completion(.success(try await rsaEncrypt(data, publicKey: publicKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func rsaDecrypt(_ data: Data, privateKey: SecKey, algorithm: FKRSAEncryptionAlgorithm, completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void) {
    Task {
      do { completion(.success(try await rsaDecrypt(data, privateKey: privateKey, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

