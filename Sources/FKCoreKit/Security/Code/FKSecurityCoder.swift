import Foundation

/// Default implementation of FKSecurityCoding.
public struct FKSecurityCoder: FKSecurityCoding, Sendable {
  public init() {}

  public func base64Encode(_ data: Data) -> String {
    data.base64EncodedString()
  }

  public func base64Decode(_ string: String) throws -> Data {
    guard let data = Data(base64Encoded: string) else {
      throw FKSecurityError.invalidInput("Invalid Base64 string.")
    }
    return data
  }

  public func urlEncode(_ string: String) -> String {
    let allowed = CharacterSet.urlQueryAllowed
    return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
  }

  public func urlDecode(_ string: String) -> String {
    string.removingPercentEncoding ?? string
  }

  public func hexString(from data: Data, uppercase: Bool = false) -> String {
    let format = uppercase ? "%02X" : "%02x"
    return data.map { String(format: format, $0) }.joined()
  }

  public func data(fromHex hex: String) throws -> Data {
    let cleaned = hex
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "\n", with: "")
      .replacingOccurrences(of: "\t", with: "")
      .replacingOccurrences(of: "\r", with: "")

    guard cleaned.count % 2 == 0 else {
      throw FKSecurityError.invalidInput("HEX string length must be even.")
    }

    var data = Data()
    data.reserveCapacity(cleaned.count / 2)

    var index = cleaned.startIndex
    while index < cleaned.endIndex {
      let next = cleaned.index(index, offsetBy: 2)
      let byteString = String(cleaned[index..<next])
      guard let byte = UInt8(byteString, radix: 16) else {
        throw FKSecurityError.invalidInput("Invalid HEX byte: \(byteString)")
      }
      data.append(byte)
      index = next
    }
    return data
  }
}

