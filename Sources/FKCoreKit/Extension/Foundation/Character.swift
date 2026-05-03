import Foundation

public extension Character {
  /// `true` when the character is represented by a single Unicode scalar and that scalar is ASCII.
  var fk_isASCII: Bool {
    guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else { return false }
    return scalar.isASCII
  }

  /// `true` when the character is considered a newline (`\n`, `\r`, Unicode line/paragraph separators).
  var fk_isNewline: Bool {
    if let scalar = unicodeScalars.first, unicodeScalars.count == 1 {
      return CharacterSet.newlines.contains(scalar)
    }
    return false
  }
}
