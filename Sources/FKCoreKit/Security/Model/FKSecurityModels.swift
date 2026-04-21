import Foundation
import Security

/// Supported hash algorithms.
public enum FKHashAlgorithm: Sendable, Equatable {
  case md5
  case sha1
  case sha256
  case sha512
}

/// AES operation mode.
public enum FKAESMode: Sendable, Equatable {
  /// CBC mode requires a 16-byte IV.
  case cbc
  /// ECB mode ignores IV.
  case ecb
}

/// Supported HMAC algorithms.
public enum FKHMACAlgorithm: Sendable, Equatable {
  case sha256
  case sha512
}

/// RSA encryption algorithms.
public enum FKRSAEncryptionAlgorithm: Sendable, Equatable {
  /// RSAES-PKCS1-v1_5.
  case pkcs1
  /// RSA-OAEP with SHA-256.
  case oaepSHA256
}

/// RSA signature algorithms.
public enum FKRSAKindOfSignature: Sendable, Equatable {
  /// RSASSA-PKCS1-v1_5 with SHA-256.
  case pkcs1v15SHA256
  /// RSASSA-PKCS1-v1_5 with SHA-512.
  case pkcs1v15SHA512
}

/// RSA key pair container.
public struct FKRSAKeyPair: @unchecked Sendable, Equatable {
  public let publicKey: SecKey
  public let privateKey: SecKey
  public let tag: String

  public init(publicKey: SecKey, privateKey: SecKey, tag: String) {
    self.publicKey = publicKey
    self.privateKey = privateKey
    self.tag = tag
  }

  public static func == (lhs: FKRSAKeyPair, rhs: FKRSAKeyPair) -> Bool {
    lhs.publicKey == rhs.publicKey && lhs.privateKey == rhs.privateKey && lhs.tag == rhs.tag
  }
}

