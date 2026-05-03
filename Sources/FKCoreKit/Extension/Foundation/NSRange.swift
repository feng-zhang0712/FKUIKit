import Foundation

public extension NSRange {
  /// `true` when the range is not `NSNotFound`, is non-negative, and fits within a UTF-16 string length.
  func fk_isValid(forUTF16Length maxLength: Int) -> Bool {
    guard location != NSNotFound else { return false }
    guard length >= 0, location >= 0, maxLength >= 0 else { return false }
    return location + length <= maxLength
  }

  /// Returns a range with `length` reduced so that `location + length` does not exceed `maxLength`.
  func fk_clamped(toUTF16Length maxLength: Int) -> NSRange {
    guard location != NSNotFound, location >= 0, maxLength >= 0 else {
      return NSRange(location: 0, length: 0)
    }
    let maxLen = max(0, maxLength - location)
    return NSRange(location: location, length: min(max(0, length), maxLen))
  }
}
