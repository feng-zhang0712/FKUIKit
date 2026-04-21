import Foundation

/// Default validator used by `FKTextField`.
///
/// The default validator mirrors the built-in `FKTextFieldFormatType` cases and provides
/// pragmatic validation rules commonly used in production apps.
public struct FKTextFieldDefaultValidator: FKTextFieldValidating {
  /// Creates a validator.
  public init() {}

  /// Validates text under the active rule.
  ///
  /// - Parameters:
  ///   - rawText: Text without separators (the canonical value for validation).
  ///   - formattedText: UI display text. Not used by the default implementation.
  ///   - rule: Active input rule.
  /// - Returns: A validation result describing validity and an optional error message.
  public func validate(
    rawText: String,
    formattedText _: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult {
    if let maxLength = rule.maxLength, rawText.count > maxLength {
      // Hard guard for global max length constraints.
      return .init(isValid: false, message: "Input exceeds max length.")
    }

    switch rule.formatType {
    case .phoneNumber:
      // Phone numbers: 11 digits (CN common format).
      let valid = rawText.count == 11
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Phone number must be 11 digits.")
    case .idCard:
      // ID card: 15-digit numeric or 18-digit with checksum validation.
      let valid = validateIDCard(rawText)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid ID card format.")
    case .bankCard:
      // Bank cards: allow common length range.
      let valid = (12 ... 24).contains(rawText.count)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Bank card length is invalid.")
    case let .verificationCode(length, _):
      // Verification codes: fixed length required.
      let valid = rawText.count == length
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Verification code is incomplete.")
    case let .password(minLength, _, validatesStrength):
      // Password: minimum length, optional strength requirements.
      let lengthValid = rawText.count >= minLength
      if !lengthValid {
        return .init(isValid: false, message: rawText.isEmpty ? nil : "Password is too short.")
      }
      if validatesStrength {
        // Strength rule: at least one uppercase, one lowercase, one digit, and minimum 8 chars.
        let strong = rawText.range(of: "(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).{8,}", options: .regularExpression) != nil
        return .init(isValid: strong, message: strong ? nil : "Password must include uppercase, lowercase and number.")
      }
      return .valid
    case let .amount(_, decimalDigits):
      // Amount: digits with optional fractional part up to the configured scale.
      let expression = "^\\d+(\\.\\d{0,\(max(0, decimalDigits))})?$"
      let valid = rawText.range(of: expression, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid amount format.")
    case .email:
      // Email: pragmatic regex for common addresses.
      let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
      let valid = rawText.range(of: regex, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid email address.")
    case .numeric:
      // Numeric: digits only.
      let valid = rawText.allSatisfy(\.isNumber)
      return .init(isValid: valid, message: valid ? nil : "Only numbers are allowed.")
    case .alphabetic:
      // Alphabetic: letters only.
      let valid = rawText.allSatisfy(\.isLetter)
      return .init(isValid: valid, message: valid ? nil : "Only letters are allowed.")
    case .alphaNumeric:
      // Alphanumeric: letters and digits only.
      let valid = rawText.allSatisfy { $0.isNumber || $0.isLetter }
      return .init(isValid: valid, message: valid ? nil : "Only letters and numbers are allowed.")
    case let .custom(regex, _, _, _):
      // Custom: validate raw value matches the provided regex repeatedly.
      let valid = rawText.range(of: "^\(regex)*$", options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid custom input.")
    }
  }
}

private extension FKTextFieldDefaultValidator {
  /// Validates Chinese Resident Identity Card numbers (15 or 18 characters).
  ///
  /// - Parameter id: Raw ID string (digits plus optional `X` for 18-digit checksum).
  /// - Returns: `true` if the ID is structurally valid.
  func validateIDCard(_ id: String) -> Bool {
    if id.count == 15 {
      // 15-digit IDs are validated as numeric-only.
      return id.allSatisfy(\.isNumber)
    }
    guard id.count == 18 else { return false }
    let body = id.prefix(17)
    let check = id.suffix(1).uppercased()
    guard body.allSatisfy(\.isNumber) else { return false }
    // 18-digit checksum: weighted sum modulo 11 mapped to parity table.
    let factors = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
    let parity = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
    let sum = zip(body, factors).reduce(0) { partial, item in
      partial + (Int(String(item.0)) ?? 0) * item.1
    }
    return parity[sum % 11] == check
  }
}

