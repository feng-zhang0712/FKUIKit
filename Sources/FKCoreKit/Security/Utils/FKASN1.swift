import Foundation

/// Minimal ASN.1 DER reader/writer helpers for RSA key import/export.
///
/// - Note: This is intentionally minimal and only supports what FKSecurity needs:
///   - PKCS#8 private keys wrapping PKCS#1 RSAPrivateKey
///   - SubjectPublicKeyInfo (SPKI) wrapping PKCS#1 RSAPublicKey
enum FKASN1 {
  // MARK: - DER Reader

  struct Reader {
    private let data: Data
    private var index: Int = 0

    init(_ data: Data) {
      self.data = data
    }

    mutating func readElement() throws -> (tag: UInt8, content: Data) {
      guard index < data.count else { throw FKSecurityError.invalidInput("ASN.1: unexpected end.") }
      let tag = data[index]
      index += 1
      let length = try readLength()
      guard index + length <= data.count else { throw FKSecurityError.invalidInput("ASN.1: invalid length.") }
      let content = data.subdata(in: index..<(index + length))
      index += length
      return (tag, content)
    }

    private mutating func readLength() throws -> Int {
      guard index < data.count else { throw FKSecurityError.invalidInput("ASN.1: missing length.") }
      let first = data[index]
      index += 1
      if first & 0x80 == 0 {
        return Int(first)
      }
      let byteCount = Int(first & 0x7F)
      guard byteCount > 0, byteCount <= 4 else {
        throw FKSecurityError.invalidInput("ASN.1: unsupported length encoding.")
      }
      guard index + byteCount <= data.count else {
        throw FKSecurityError.invalidInput("ASN.1: invalid length bytes.")
      }
      var value = 0
      for _ in 0..<byteCount {
        value = (value << 8) | Int(data[index])
        index += 1
      }
      return value
    }
  }

  // MARK: - DER Writer

  static func sequence(_ content: Data) -> Data {
    element(tag: 0x30, content: content)
  }

  static func integer(_ bytes: Data) -> Data {
    // Ensure positive integer (prefix 0x00 when highest bit is set).
    var b = bytes
    if let first = b.first, first & 0x80 != 0 {
      b.insert(0x00, at: 0)
    }
    return element(tag: 0x02, content: b)
  }

  static func octetString(_ content: Data) -> Data {
    element(tag: 0x04, content: content)
  }

  static func bitString(_ content: Data) -> Data {
    // DER BIT STRING requires leading unused-bits count byte. We use 0.
    var c = Data([0x00])
    c.append(content)
    return element(tag: 0x03, content: c)
  }

  static func null() -> Data {
    element(tag: 0x05, content: Data())
  }

  static func objectIdentifier(_ oid: [UInt64]) throws -> Data {
    guard oid.count >= 2 else {
      throw FKSecurityError.invalidInput("ASN.1: invalid OID.")
    }
    var body = Data()
    body.append(UInt8(oid[0] * 40 + oid[1]))
    for value in oid.dropFirst(2) {
      body.append(contentsOf: base128(value))
    }
    return element(tag: 0x06, content: body)
  }

  static func element(tag: UInt8, content: Data) -> Data {
    var out = Data([tag])
    out.append(lengthBytes(content.count))
    out.append(content)
    return out
  }

  private static func lengthBytes(_ length: Int) -> Data {
    if length < 0x80 {
      return Data([UInt8(length)])
    }
    var bytes: [UInt8] = []
    var value = length
    while value > 0 {
      bytes.insert(UInt8(value & 0xFF), at: 0)
      value >>= 8
    }
    return Data([0x80 | UInt8(bytes.count)] + bytes)
  }

  private static func base128(_ value: UInt64) -> [UInt8] {
    var v = value
    var bytes: [UInt8] = [UInt8(v & 0x7F)]
    v >>= 7
    while v > 0 {
      bytes.insert(UInt8(v & 0x7F) | 0x80, at: 0)
      v >>= 7
    }
    return bytes
  }
}

