import Foundation

/// Default implementation of ``FKBusinessMasking``.
public final class FKBusinessMasker: FKBusinessMasking, @unchecked Sendable {
  /// Creates masking helper.
  public init() {}

  /// Masks phone number, keeping first 3 and last 4 digits when possible.
  ///
  /// - Parameter input: Original phone string.
  /// - Returns: Masked phone string.
  public func maskPhone(_ input: String) -> String {
    let digits = input.filter(\.isNumber)
    guard digits.count >= 7 else { return mask(input, keepPrefix: 1, keepSuffix: 1, maskCharacter: "*") }
    return mask(digits, keepPrefix: 3, keepSuffix: 4, maskCharacter: "*")
  }

  /// Masks ID string, keeping first 6 and last 4 characters when possible.
  ///
  /// - Parameter input: Original ID string.
  /// - Returns: Masked ID text.
  public func maskIDCard(_ input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 8 else { return mask(trimmed, keepPrefix: 1, keepSuffix: 1, maskCharacter: "*") }
    return mask(trimmed, keepPrefix: 6, keepSuffix: 4, maskCharacter: "*")
  }

  /// Masks email local-part while preserving domain.
  ///
  /// - Parameter input: Original email text.
  /// - Returns: Masked email text.
  public func maskEmail(_ input: String) -> String {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
    guard parts.count == 2 else { return mask(trimmed, keepPrefix: 1, keepSuffix: 1, maskCharacter: "*") }
    let name = String(parts[0])
    let domain = String(parts[1])
    let maskedName = mask(name, keepPrefix: 1, keepSuffix: 0, maskCharacter: "*")
    return "\(maskedName)@\(domain)"
  }

  /// Masks arbitrary string while preserving configured prefix/suffix.
  ///
  /// - Parameters:
  ///   - input: Original text.
  ///   - keepPrefix: Number of leading characters to preserve.
  ///   - keepSuffix: Number of trailing characters to preserve.
  ///   - maskCharacter: Character used to replace hidden range.
  /// - Returns: Masked text.
  public func mask(_ input: String, keepPrefix: Int, keepSuffix: Int, maskCharacter: Character = "*") -> String {
    guard keepPrefix >= 0, keepSuffix >= 0 else { return input }
    guard input.count > keepPrefix + keepSuffix else { return input }
    let prefix = String(input.prefix(keepPrefix))
    let suffix = String(input.suffix(keepSuffix))
    let maskCount = max(0, input.count - keepPrefix - keepSuffix)
    return prefix + String(repeating: String(maskCharacter), count: maskCount) + suffix
  }
}

