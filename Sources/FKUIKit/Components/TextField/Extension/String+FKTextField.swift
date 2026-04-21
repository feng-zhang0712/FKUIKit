import Foundation

/// String utilities used by `FKTextField` formatters and validators.
///
/// These helpers are intentionally lightweight and allocation-friendly to keep input
/// processing fast in list-heavy UIs.
extension String {
  /// Returns whether a scalar should be treated as an emoji character for filtering.
  ///
  /// This intentionally excludes ASCII scalars (e.g. digits `0-9`) because some of them
  /// can participate in emoji sequences (keycap) but should still be accepted as text input.
  fileprivate static func fk_isEmojiScalar(_ scalar: UnicodeScalar) -> Bool {
    if scalar.properties.isEmojiPresentation {
      return true
    }
    return scalar.properties.isEmoji && !scalar.isASCII
  }

  /// Returns a string that keeps only decimal digits.
  var fk_digitsOnly: String {
    filter(\.isNumber)
  }

  /// Returns a string that keeps only ASCII letters.
  var fk_lettersOnly: String {
    filter { $0.isASCII && $0.isLetter }
  }

  /// Returns a string that keeps only ASCII letters and numbers.
  var fk_alphaNumericOnly: String {
    filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
  }

  /// Returns whether the string contains emoji scalar.
  var fk_containsEmoji: Bool {
    // Keep detection aligned with filtering logic so ASCII digits are not flagged as emoji.
    unicodeScalars.contains { Self.fk_isEmojiScalar($0) }
  }

  /// Returns a grouped representation.
  ///
  /// - Parameters:
  ///   - separator: Separator inserted between groups (default is a space).
  ///   - pattern: Group sizes. If the pattern ends, the last size repeats.
  /// - Returns: A grouped string used for UI display.
  func fk_grouped(separator: Character = " ", pattern: [Int]) -> String {
    guard !pattern.isEmpty else { return self }
    var output = ""
    var index = startIndex
    var patternIndex = 0
    while index < endIndex {
      // Pick the current group length; once pattern is exhausted, reuse the last length.
      let groupLength = pattern[min(patternIndex, pattern.count - 1)]
      guard groupLength > 0 else { break }
      let nextIndex = self.index(index, offsetBy: groupLength, limitedBy: endIndex) ?? endIndex
      if !output.isEmpty {
        output.append(separator)
      }
      output.append(contentsOf: self[index..<nextIndex])
      index = nextIndex
      if patternIndex < pattern.count - 1 {
        patternIndex += 1
      }
    }
    return output
  }

  /// Truncates string to a maximum count.
  ///
  /// - Parameter count: Maximum character count. Values less than `0` return an empty string.
  /// - Returns: Truncated string that is safe for UI and validation rules.
  func fk_truncated(to count: Int) -> String {
    guard count >= 0 else { return "" }
    if self.count <= count {
      return self
    }
    return String(prefix(count))
  }
}

