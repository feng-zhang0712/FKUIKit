import Foundation

/// A composable synchronous validator rule.
public struct FKTextFieldValidationRule: Sendable {
  /// Validation closure.
  public let validate: @Sendable (_ raw: String, _ formatted: String, _ inputRule: FKTextFieldInputRule) -> FKTextFieldValidationResult

  /// Creates a validation rule.
  public init(
    validate: @escaping @Sendable (_ raw: String, _ formatted: String, _ inputRule: FKTextFieldInputRule) -> FKTextFieldValidationResult
  ) {
    self.validate = validate
  }
}

/// Chain-based validator that short-circuits on first failure.
public struct FKTextFieldCompositeValidator: FKTextFieldValidating {
  /// Ordered rules to execute.
  public var rules: [FKTextFieldValidationRule]

  /// Creates a composite validator.
  public init(rules: [FKTextFieldValidationRule]) {
    self.rules = rules
  }

  public func validate(
    rawText: String,
    formattedText: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult {
    for entry in rules {
      let result = entry.validate(rawText, formattedText, rule)
      if !result.isValid {
        return result
      }
    }
    return .valid
  }
}

public extension FKTextFieldValidationRule {
  /// Requires input not to be empty.
  static func required(message: String = "This field is required.") -> Self {
    .init { raw, _, _ in
      raw.isEmpty ? .init(isValid: false, message: message) : .valid
    }
  }

  /// Requires minimum length.
  static func minLength(_ value: Int, message: String? = nil) -> Self {
    .init { raw, _, _ in
      let passed = raw.count >= max(0, value)
      return .init(isValid: passed, message: passed ? nil : (message ?? "Input is too short."))
    }
  }

  /// Requires maximum length.
  static func maxLength(_ value: Int, message: String? = nil) -> Self {
    .init { raw, _, _ in
      let passed = raw.count <= max(0, value)
      return .init(isValid: passed, message: passed ? nil : (message ?? "Input exceeds max length."))
    }
  }

  /// Requires full-text regex match.
  static func regex(_ pattern: String, message: String = "Invalid format.") -> Self {
    .init { raw, _, _ in
      let matched = raw.range(of: pattern, options: .regularExpression) != nil
      return .init(isValid: matched, message: matched ? nil : message)
    }
  }
}

