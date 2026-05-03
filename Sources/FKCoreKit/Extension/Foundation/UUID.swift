import Foundation

public extension UUID {
  /// 32-character lowercase hex string without hyphens.
  var fk_compactHexString: String {
    uuidString.replacingOccurrences(of: "-", with: "").lowercased()
  }

  /// Parses a 32-character hex string (hyphens optional, case-insensitive).
  init?(fk_hexString string: String) {
    let cleaned = string
      .replacingOccurrences(of: "-", with: "")
      .lowercased()
    guard cleaned.count == 32 else { return nil }
    var bytes = [UInt8]()
    bytes.reserveCapacity(16)
    var index = cleaned.startIndex
    for _ in 0..<16 {
      let next = cleaned.index(index, offsetBy: 2)
      guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
      bytes.append(byte)
      index = next
    }
    self = UUID(uuid: (
      bytes[0], bytes[1], bytes[2], bytes[3],
      bytes[4], bytes[5], bytes[6], bytes[7],
      bytes[8], bytes[9], bytes[10], bytes[11],
      bytes[12], bytes[13], bytes[14], bytes[15]
    ))
  }
}
