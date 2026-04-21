import Foundation

/// Protocol describing regex and validation utilities.
public protocol FKRegexUtilsProviding {
  /// Returns whether text fully matches the given pattern.
  func isMatch(_ text: String, pattern: String, options: NSRegularExpression.Options) -> Bool
  /// Extracts all matches for a pattern.
  func matches(in text: String, pattern: String, options: NSRegularExpression.Options) -> [String]
  /// Replaces matches for a pattern.
  func replacing(_ text: String, pattern: String, with template: String, options: NSRegularExpression.Options) -> String
}

/// Default implementation of ``FKRegexUtilsProviding``.
public struct FKRegexUtilsProvider: FKRegexUtilsProviding {
  private let cache = NSCache<NSString, NSRegularExpression>()

  public init() {}

  public func isMatch(_ text: String, pattern: String, options: NSRegularExpression.Options = []) -> Bool {
    guard let regex = regex(pattern: pattern, options: options) else { return false }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let first = regex.firstMatch(in: text, options: [], range: range) else { return false }
    return first.range == range
  }

  public func matches(in text: String, pattern: String, options: NSRegularExpression.Options = []) -> [String] {
    guard let regex = regex(pattern: pattern, options: options) else { return [] }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.matches(in: text, options: [], range: range).compactMap { result in
      guard let swiftRange = Range(result.range, in: text) else { return nil }
      return String(text[swiftRange])
    }
  }

  public func replacing(_ text: String, pattern: String, with template: String, options: NSRegularExpression.Options = []) -> String {
    guard let regex = regex(pattern: pattern, options: options) else { return text }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
  }

  /// Builds or returns a cached regex instance.
  private func regex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
    let key = "\(pattern)|\(options.rawValue)" as NSString
    if let cached = cache.object(forKey: key) { return cached }
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
    cache.setObject(regex, forKey: key)
    return regex
  }
}

/// Static facade for regex and validation helpers.
public enum FKUtilsRegex {
  /// Thread-safe provider storage used to avoid shared mutable global state.
  private final class ProviderStore: @unchecked Sendable {
    private let lock = NSLock()
    private var provider: FKRegexUtilsProviding = FKRegexUtilsProvider()

    func set(_ provider: FKRegexUtilsProviding) {
      lock.lock()
      defer { lock.unlock() }
      self.provider = provider
    }

    func get() -> FKRegexUtilsProviding {
      lock.lock()
      defer { lock.unlock() }
      return provider
    }
  }

  private static let store = ProviderStore()

  /// Common regex patterns.
  public enum Pattern {
    public static let phoneCN = #"^1[3-9]\d{9}$"#
    public static let email = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    public static let idCardCN = #"^(\d{15}|\d{17}[\dXx])$"#
    public static let passwordStrong = #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[^\w\s]).{8,}$"#
    public static let verificationCode4To8 = #"^\d{4,8}$"#
    public static let licensePlateCN = #"^[\u4e00-\u9fa5][A-Z][A-Z0-9]{5,6}$"#
    public static let url = #"^https?://[\w.-]+(?:\.[\w\.-]+)+(?:[/\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+)?$"#
    public static let ipV4 = #"^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$"#
    public static let postalCodeCN = #"^\d{6}$"#
    public static let bankCard = #"^\d{12,19}$"#
  }

  /// Replaces default provider for customization.
  public static func register(provider newProvider: FKRegexUtilsProviding) {
    store.set(newProvider)
  }

  /// Performs full regex match.
  public static func isMatch(_ text: String, pattern: String, options: NSRegularExpression.Options = []) -> Bool {
    let current = store.get()
    return current.isMatch(text, pattern: pattern, options: options)
  }

  /// Extracts all matching fragments.
  public static func extract(_ text: String, pattern: String, options: NSRegularExpression.Options = []) -> [String] {
    let current = store.get()
    return current.matches(in: text, pattern: pattern, options: options)
  }

  /// Replaces matching fragments.
  public static func replace(_ text: String, pattern: String, with template: String, options: NSRegularExpression.Options = []) -> String {
    let current = store.get()
    return current.replacing(text, pattern: pattern, with: template, options: options)
  }

  /// Validates phone number.
  public static func isValidPhone(_ text: String) -> Bool { isMatch(text, pattern: Pattern.phoneCN) }
  /// Validates email.
  public static func isValidEmail(_ text: String) -> Bool { isMatch(text, pattern: Pattern.email) }
  /// Validates Chinese ID card.
  public static func isValidIDCard(_ text: String) -> Bool { isMatch(text, pattern: Pattern.idCardCN) }
  /// Validates strong password.
  public static func isStrongPassword(_ text: String) -> Bool { isMatch(text, pattern: Pattern.passwordStrong) }
  /// Validates verification code.
  public static func isValidVerificationCode(_ text: String) -> Bool { isMatch(text, pattern: Pattern.verificationCode4To8) }
  /// Validates Chinese license plate.
  public static func isValidLicensePlate(_ text: String) -> Bool { isMatch(text, pattern: Pattern.licensePlateCN) }
  /// Validates URL.
  public static func isValidURL(_ text: String) -> Bool { isMatch(text, pattern: Pattern.url) }
  /// Validates IPv4 address.
  public static func isValidIPv4(_ text: String) -> Bool { isMatch(text, pattern: Pattern.ipV4) }
  /// Validates postal code.
  public static func isValidPostalCode(_ text: String) -> Bool { isMatch(text, pattern: Pattern.postalCodeCN) }
  /// Validates bank card using regex and Luhn.
  public static func isValidBankCard(_ text: String) -> Bool {
    guard isMatch(text, pattern: Pattern.bankCard) else { return false }
    return luhnCheck(text)
  }

  /// Performs Luhn check for bank card numbers.
  private static func luhnCheck(_ text: String) -> Bool {
    let digits = text.compactMap(\.wholeNumberValue).reversed()
    var sum = 0
    for (index, value) in digits.enumerated() {
      if index % 2 == 1 {
        let doubled = value * 2
        sum += doubled > 9 ? doubled - 9 : doubled
      } else {
        sum += value
      }
    }
    return sum % 10 == 0
  }
}
