import Foundation

/// Static string processing and conversion helpers.
public enum FKUtilsString {
  /// Returns substring by safe range.
  public static func substring(_ text: String, from start: Int, length: Int) -> String {
    guard start >= 0, length > 0, start < text.count else { return "" }
    let lower = text.index(text.startIndex, offsetBy: start)
    let upper = text.index(lower, offsetBy: min(length, text.count - start), limitedBy: text.endIndex) ?? text.endIndex
    return String(text[lower..<upper])
  }

  /// Joins string fragments with separator.
  public static func join(_ items: [String], separator: String = "") -> String {
    items.joined(separator: separator)
  }

  /// Trims whitespaces and newlines.
  public static func trim(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Removes all spaces and line breaks.
  public static func removeWhitespacesAndNewlines(_ text: String) -> String {
    text.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
  }

  /// Removes special characters but keeps letters, numbers and spaces.
  public static func removeSpecialCharacters(_ text: String) -> String {
    text.replacingOccurrences(of: #"[^A-Za-z0-9\u4e00-\u9fa5\s]"#, with: "", options: .regularExpression)
  }

  /// Masks a phone number.
  public static func maskPhone(_ text: String) -> String {
    let digits = text.filter(\.isNumber)
    guard digits.count >= 7 else { return text }
    return "\(digits.prefix(3))****\(digits.suffix(4))"
  }

  /// Masks Chinese ID card.
  public static func maskIDCard(_ text: String) -> String {
    guard text.count > 8 else { return text }
    return "\(text.prefix(4))\(String(repeating: "*", count: text.count - 8))\(text.suffix(4))"
  }

  /// Masks email address.
  public static func maskEmail(_ text: String) -> String {
    let parts = text.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
    guard parts.count == 2 else { return text }
    let name = String(parts[0])
    let domain = String(parts[1])
    guard !name.isEmpty else { return text }
    let masked = name.count <= 2 ? "\(name.prefix(1))*" : "\(name.prefix(1))\(String(repeating: "*", count: name.count - 2))\(name.suffix(1))"
    return "\(masked)@\(domain)"
  }

  /// Masks bank card number.
  public static func maskBankCard(_ text: String) -> String {
    let digits = text.filter(\.isNumber)
    guard digits.count > 8 else { return text }
    return "\(digits.prefix(4)) \(String(repeating: "*", count: max(0, digits.count - 8))) \(digits.suffix(4))"
  }

  /// Returns text length by composed characters.
  public static func length(_ text: String) -> Int { text.count }

  /// Returns whether text is empty after trimming.
  public static func isBlank(_ text: String?) -> Bool {
    guard let text else { return true }
    return trim(text).isEmpty
  }

  /// Converts Chinese text to pinyin.
  public static func pinyin(from text: String, dropDiacritics: Bool = true) -> String {
    let mutable = NSMutableString(string: text) as CFMutableString
    CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
    if dropDiacritics {
      CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false)
    }
    return (mutable as String).lowercased()
  }

  /// Returns uppercase first letter of pinyin.
  public static func firstLetter(_ text: String) -> String {
    guard let first = pinyin(from: text).first else { return "#" }
    let letter = String(first).uppercased()
    return letter.range(of: "[A-Z]", options: .regularExpression) != nil ? letter : "#"
  }

  /// Encodes URL query fragment.
  public static func urlEncode(_ text: String) -> String {
    text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
  }

  /// Decodes URL encoded text.
  public static func urlDecode(_ text: String) -> String {
    text.removingPercentEncoding ?? text
  }

  /// Encodes text as Base64 string.
  public static func base64Encode(_ text: String) -> String {
    Data(text.utf8).base64EncodedString()
  }

  /// Decodes Base64 string into text.
  public static func base64Decode(_ text: String) -> String? {
    guard let data = Data(base64Encoded: text) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// Escapes HTML entities.
  public static func htmlEscape(_ text: String) -> String {
    text
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }

  /// Unescapes HTML entities.
  public static func htmlUnescape(_ text: String) -> String {
    text
      .replacingOccurrences(of: "&lt;", with: "<")
      .replacingOccurrences(of: "&gt;", with: ">")
      .replacingOccurrences(of: "&quot;", with: "\"")
      .replacingOccurrences(of: "&#39;", with: "'")
      .replacingOccurrences(of: "&amp;", with: "&")
  }
}
