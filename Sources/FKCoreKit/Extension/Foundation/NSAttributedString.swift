import Foundation

public extension NSAttributedString {
  /// Range covering the entire string (`0..<length`).
  var fk_fullRange: NSRange {
    NSRange(location: 0, length: length)
  }

  /// Returns a copy with `attributes` applied across the full range (existing attributes at a key are replaced).
  func fk_applying(attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
    let mutable = NSMutableAttributedString(attributedString: self)
    mutable.addAttributes(attributes, range: fk_fullRange)
    return mutable
  }
}
