import Foundation

/// FKSecurity is a pure-native Swift security and cryptography component for FKCoreKit.
///
/// - Important:
///   - No third-party dependencies.
///   - Uses only system frameworks (`Foundation`, `Security`, and Apple-provided `CommonCrypto`).
///   - All heavy operations are executed off the main thread.
public final class FKSecurity: @unchecked Sendable {
  /// Shared singleton for global usage.
  public static let shared = FKSecurity()

  /// Hashing service.
  public let hash: FKHashing
  /// AES service.
  public let aes: FKAESCrypting
  /// RSA service.
  public let rsa: FKRSACrypting
  /// Encoding and conversion utilities.
  public let code: FKSecurityCoding
  /// HMAC and parameter signing service.
  public let sign: FKSecuritySigning
  /// Security utilities.
  public let utils: FKSecurityUtilizing
  /// Key storage (Keychain-backed by default).
  public let keys: FKSecurityKeyStoring

  private let executor: FKSecurityExecuting

  /// Creates FKSecurity with custom service implementations.
  ///
  /// - Note: This initializer is public to support dependency injection in tests.
  public init(
    executor: FKSecurityExecuting = FKSecurityExecutor(),
    hash: FKHashing? = nil,
    aes: FKAESCrypting? = nil,
    rsa: FKRSACrypting? = nil,
    code: FKSecurityCoding? = nil,
    sign: FKSecuritySigning? = nil,
    utils: FKSecurityUtilizing? = nil,
    keys: FKSecurityKeyStoring? = nil
  ) {
    self.executor = executor
    self.code = code ?? FKSecurityCoder()
    self.keys = keys ?? FKKeychainKeyStore(service: "com.fkkit.security.keys")
    self.hash = hash ?? FKHashService(executor: executor, coder: self.code)
    self.aes = aes ?? FKAESService(executor: executor)
    self.rsa = rsa ?? FKRSAService(executor: executor)
    self.sign = sign ?? FKSignatureService(executor: executor, coder: self.code)
    self.utils = utils ?? FKSecurityUtils(executor: executor, hasher: self.hash)
  }
}

