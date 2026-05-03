import Foundation

public extension Data {
  /// Lowercase hexadecimal string representation of the bytes.
  var fk_hexEncodedString: String {
    map { String(format: "%02x", $0) }.joined()
  }

  /// Uppercase hexadecimal string representation of the bytes.
  var fk_hexEncodedStringUppercased: String {
    map { String(format: "%02X", $0) }.joined()
  }

  /// Human-readable byte size (1024-based), e.g. `"1.2 MB"`.
  var fk_byteCountDescription: String {
    ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
  }
}

public extension Data {
  /// Creates data from a hexadecimal string; returns `nil` when the string is invalid.
  init?(fk_hexEncoded hex: String) {
    let cleaned = hex.replacingOccurrences(of: " ", with: "")
    guard cleaned.count.isMultiple(of: 2) else { return nil }
    var bytes = [UInt8]()
    bytes.reserveCapacity(cleaned.count / 2)
    var index = cleaned.startIndex
    while index < cleaned.endIndex {
      let next = cleaned.index(index, offsetBy: 2)
      guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
      bytes.append(byte)
      index = next
    }
    self.init(bytes)
  }
}
