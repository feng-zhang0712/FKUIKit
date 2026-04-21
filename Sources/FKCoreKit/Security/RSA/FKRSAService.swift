import Foundation
import Security

/// Default RSA implementation using the Security framework.
public final class FKRSAService: FKRSACrypting, @unchecked Sendable {
  private let executor: FKSecurityExecuting

  public init(executor: FKSecurityExecuting) {
    self.executor = executor
  }

  public func generateKeyPair(keySize: Int = 2048, tag: String, storeInKeychain: Bool = true) async throws -> FKRSAKeyPair {
    try await executor.run {
      guard [2048, 3072, 4096].contains(keySize) else {
        throw FKSecurityError.invalidInput("RSA keySize must be 2048/3072/4096.")
      }

      let tagData = tag.data(using: .utf8) ?? Data(tag.utf8)
      let privateAttrs: [String: Any] = [
        kSecAttrIsPermanent as String: storeInKeychain,
        kSecAttrApplicationTag as String: tagData,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      ]

      let parameters: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: keySize,
        kSecPrivateKeyAttrs as String: privateAttrs,
      ]

      var error: Unmanaged<CFError>?
      guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error) else {
        let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateRandomKey failed."
        throw FKSecurityError.securityFailed(status: errSecParam, message: message)
      }
      guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        throw FKSecurityError.unavailable("SecKeyCopyPublicKey returned nil.")
      }
      return FKRSAKeyPair(publicKey: publicKey, privateKey: privateKey, tag: tag)
    }
  }

  public func publicKey(from privateKey: SecKey) async throws -> SecKey {
    try await executor.run {
      guard let pub = SecKeyCopyPublicKey(privateKey) else {
        throw FKSecurityError.unavailable("SecKeyCopyPublicKey returned nil.")
      }
      return pub
    }
  }

  public func encrypt(_ data: Data, publicKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data {
    try await executor.run {
      var error: Unmanaged<CFError>?
      let secAlg = Self.secEncryptionAlgorithm(algorithm)
      guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, secAlg) else {
        throw FKSecurityError.unavailable("RSA encryption algorithm is not supported by this key.")
      }
      guard let out = SecKeyCreateEncryptedData(publicKey, secAlg, data as CFData, &error) as Data? else {
        let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateEncryptedData failed."
        throw FKSecurityError.unknown(message)
      }
      return out
    }
  }

  public func decrypt(_ data: Data, privateKey: SecKey, algorithm: FKRSAEncryptionAlgorithm) async throws -> Data {
    try await executor.run {
      var error: Unmanaged<CFError>?
      let secAlg = Self.secEncryptionAlgorithm(algorithm)
      guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, secAlg) else {
        throw FKSecurityError.unavailable("RSA decryption algorithm is not supported by this key.")
      }
      guard let out = SecKeyCreateDecryptedData(privateKey, secAlg, data as CFData, &error) as Data? else {
        let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateDecryptedData failed."
        throw FKSecurityError.unknown(message)
      }
      return out
    }
  }

  public func sign(_ data: Data, privateKey: SecKey, algorithm: FKRSAKindOfSignature) async throws -> Data {
    try await executor.run {
      var error: Unmanaged<CFError>?
      let secAlg = Self.secSignatureAlgorithm(algorithm)
      guard SecKeyIsAlgorithmSupported(privateKey, .sign, secAlg) else {
        throw FKSecurityError.unavailable("RSA signature algorithm is not supported by this key.")
      }
      guard let out = SecKeyCreateSignature(privateKey, secAlg, data as CFData, &error) as Data? else {
        let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateSignature failed."
        throw FKSecurityError.unknown(message)
      }
      return out
    }
  }

  public func verify(_ signature: Data, data: Data, publicKey: SecKey, algorithm: FKRSAKindOfSignature) async throws -> Bool {
    try await executor.run {
      var error: Unmanaged<CFError>?
      let secAlg = Self.secSignatureAlgorithm(algorithm)
      guard SecKeyIsAlgorithmSupported(publicKey, .verify, secAlg) else {
        throw FKSecurityError.unavailable("RSA verification algorithm is not supported by this key.")
      }
      let ok = SecKeyVerifySignature(publicKey, secAlg, data as CFData, signature as CFData, &error)
      if let error {
        let message = (error.takeRetainedValue() as Error).localizedDescription
        throw FKSecurityError.unknown(message)
      }
      return ok
    }
  }

  public func exportPublicKeySPKIDER(_ publicKey: SecKey) async throws -> Data {
    try await executor.run {
      guard let raw = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
        throw FKSecurityError.unavailable("SecKeyCopyExternalRepresentation returned nil for public key.")
      }
      // Wrap raw PKCS#1 RSAPublicKey into SPKI.
      // AlgorithmIdentifier: rsaEncryption OID 1.2.840.113549.1.1.1 + NULL
      let rsaOID = [1, 2, 840, 113549, 1, 1, 1].map(UInt64.init)
      let algId = try FKASN1.sequence(FKASN1.objectIdentifier(rsaOID) + FKASN1.null())
      let spki = FKASN1.sequence(algId + FKASN1.bitString(raw))
      return spki
    }
  }

  public func exportPrivateKeyPKCS8DER(_ privateKey: SecKey) async throws -> Data {
    try await executor.run {
      guard let raw = SecKeyCopyExternalRepresentation(privateKey, nil) as Data? else {
        throw FKSecurityError.unavailable("SecKeyCopyExternalRepresentation returned nil for private key.")
      }
      // Wrap raw PKCS#1 RSAPrivateKey into PKCS#8 PrivateKeyInfo.
      let rsaOID = [1, 2, 840, 113549, 1, 1, 1].map(UInt64.init)
      let algId = try FKASN1.sequence(FKASN1.objectIdentifier(rsaOID) + FKASN1.null())
      let version = FKASN1.integer(Data([0x00]))
      let pkcs8 = FKASN1.sequence(version + algId + FKASN1.octetString(raw))
      return pkcs8
    }
  }

  public func importPublicKey(fromDER data: Data, isSPKI: Bool = true) async throws -> SecKey {
    try await executor.run {
      let keyData: Data
      if isSPKI {
        keyData = try Self.unwrapSPKI(data)
      } else {
        keyData = data
      }
      return try Self.createRSAPublicKey(fromPKCS1: keyData)
    }
  }

  public func importPrivateKey(fromDER data: Data, isPKCS8: Bool = true) async throws -> SecKey {
    try await executor.run {
      let keyData: Data
      if isPKCS8 {
        keyData = try Self.unwrapPKCS8(data)
      } else {
        keyData = data
      }
      return try Self.createRSAPrivateKey(fromPKCS1: keyData)
    }
  }
}

// MARK: - Algorithms

extension FKRSAService {
  private static func secEncryptionAlgorithm(_ algorithm: FKRSAEncryptionAlgorithm) -> SecKeyAlgorithm {
    switch algorithm {
    case .pkcs1:
      return .rsaEncryptionPKCS1
    case .oaepSHA256:
      return .rsaEncryptionOAEPSHA256
    }
  }

  private static func secSignatureAlgorithm(_ algorithm: FKRSAKindOfSignature) -> SecKeyAlgorithm {
    switch algorithm {
    case .pkcs1v15SHA256:
      return .rsaSignatureMessagePKCS1v15SHA256
    case .pkcs1v15SHA512:
      return .rsaSignatureMessagePKCS1v15SHA512
    }
  }
}

// MARK: - Key Import Helpers (PKCS#8 / SPKI)

extension FKRSAService {
  private static func unwrapPKCS8(_ der: Data) throws -> Data {
    var reader = FKASN1.Reader(der)
    let (tag, content) = try reader.readElement()
    guard tag == 0x30 else { throw FKSecurityError.invalidInput("PKCS#8: expected SEQUENCE.") }

    var seq = FKASN1.Reader(content)
    _ = try seq.readElement() // version INTEGER
    _ = try seq.readElement() // algorithm SEQUENCE
    let (pkTag, pkContent) = try seq.readElement()
    guard pkTag == 0x04 else { throw FKSecurityError.invalidInput("PKCS#8: expected OCTET STRING.") }
    return pkContent
  }

  private static func unwrapSPKI(_ der: Data) throws -> Data {
    var reader = FKASN1.Reader(der)
    let (tag, content) = try reader.readElement()
    guard tag == 0x30 else { throw FKSecurityError.invalidInput("SPKI: expected SEQUENCE.") }

    var seq = FKASN1.Reader(content)
    _ = try seq.readElement() // algorithm SEQUENCE
    let (bsTag, bsContent) = try seq.readElement()
    guard bsTag == 0x03 else { throw FKSecurityError.invalidInput("SPKI: expected BIT STRING.") }
    guard !bsContent.isEmpty else { throw FKSecurityError.invalidInput("SPKI: empty BIT STRING.") }
    // First byte is unused-bits count.
    return bsContent.dropFirst()
  }

  private static func createRSAPublicKey(fromPKCS1 data: Data) throws -> SecKey {
    let keySize = try rsaModulusBitLength(fromPKCS1PublicKey: data)
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
      kSecAttrKeySizeInBits as String: keySize,
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
      let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateWithData failed (public)."
      throw FKSecurityError.unknown(message)
    }
    return key
  }

  private static func createRSAPrivateKey(fromPKCS1 data: Data) throws -> SecKey {
    let keySize = try rsaModulusBitLength(fromPKCS1PrivateKey: data)
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecAttrKeySizeInBits as String: keySize,
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
      let message = (error?.takeRetainedValue() as Error?)?.localizedDescription ?? "SecKeyCreateWithData failed (private)."
      throw FKSecurityError.unknown(message)
    }
    return key
  }
}

// MARK: - RSA modulus inference

extension FKRSAService {
  /// Infers RSA modulus bit length from a PKCS#1 RSAPublicKey DER.
  private static func rsaModulusBitLength(fromPKCS1PublicKey der: Data) throws -> Int {
    var reader = FKASN1.Reader(der)
    let (tag, content) = try reader.readElement()
    guard tag == 0x30 else { throw FKSecurityError.invalidInput("RSAPublicKey: expected SEQUENCE.") }
    var seq = FKASN1.Reader(content)
    let (modTag, modContent) = try seq.readElement()
    guard modTag == 0x02 else { throw FKSecurityError.invalidInput("RSAPublicKey: expected INTEGER modulus.") }
    let modulus = stripLeadingZero(modContent)
    return modulus.count * 8
  }

  /// Infers RSA modulus bit length from a PKCS#1 RSAPrivateKey DER.
  private static func rsaModulusBitLength(fromPKCS1PrivateKey der: Data) throws -> Int {
    var reader = FKASN1.Reader(der)
    let (tag, content) = try reader.readElement()
    guard tag == 0x30 else { throw FKSecurityError.invalidInput("RSAPrivateKey: expected SEQUENCE.") }
    var seq = FKASN1.Reader(content)
    _ = try seq.readElement() // version INTEGER
    let (modTag, modContent) = try seq.readElement()
    guard modTag == 0x02 else { throw FKSecurityError.invalidInput("RSAPrivateKey: expected INTEGER modulus.") }
    let modulus = stripLeadingZero(modContent)
    return modulus.count * 8
  }

  private static func stripLeadingZero(_ integerBytes: Data) -> Data {
    if integerBytes.count >= 1, integerBytes.first == 0x00 {
      return integerBytes.dropFirst()
    }
    return integerBytes
  }
}

