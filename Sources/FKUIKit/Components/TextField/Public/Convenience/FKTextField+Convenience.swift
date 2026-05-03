import UIKit

public extension FKTextField {
  /// Creates a one-line configured text field.
  ///
  /// - Parameters:
  ///   - formatType: Built-in format type.
  ///   - placeholder: Optional placeholder text.
  ///   - maxLength: Optional max raw text length.
  /// - Returns: Configured `FKTextField`.
  static func make(
    formatType: FKTextFieldFormatType,
    placeholder: String? = nil,
    maxLength: Int? = nil
  ) -> FKTextField {
    let rule = FKTextFieldInputRule(formatType: formatType, maxLength: maxLength)
    let configuration = FKTextFieldConfiguration(
      inputRule: rule,
      style: FKTextFieldManager.shared.defaultStyle,
      localization: FKTextFieldManager.shared.defaultLocalization,
      placeholder: placeholder
    )
    return FKTextField(configuration: configuration)
  }

  /// Creates a preconfigured email field.
  static func makeEmail(placeholder: String? = "Email") -> FKTextField {
    make(formatType: .email, placeholder: placeholder)
  }

  /// Creates a preconfigured password field.
  static func makePassword(
    placeholder: String? = "Password",
    minLength: Int = 8,
    maxLength: Int = 20
  ) -> FKTextField {
    let rule = FKTextFieldInputRule(
      formatType: .password(minLength: minLength, maxLength: maxLength, validatesStrength: true),
      maxLength: maxLength,
      minLength: minLength
    )
    return FKTextField(configuration: FKTextFieldConfiguration(inputRule: rule, placeholder: placeholder))
  }

  /// Creates a preconfigured phone field.
  static func makePhone(placeholder: String? = "Phone number") -> FKTextField {
    make(formatType: .phoneNumber, placeholder: placeholder, maxLength: 11)
  }
}

/// Fluent builder for advanced text field creation.
@MainActor
public struct FKTextFieldBuilder {
  private var configuration: FKTextFieldConfiguration
  private var formatter: FKTextFieldFormatting
  private var validator: FKTextFieldValidating
  private var asyncValidator: FKTextFieldAsyncValidating?

  /// Creates a builder with base input rule.
  public init(inputRule: FKTextFieldInputRule) {
    configuration = FKTextFieldConfiguration(inputRule: inputRule, style: FKTextFieldManager.shared.defaultStyle)
    formatter = FKTextFieldDefaultFormatter()
    validator = FKTextFieldDefaultValidator()
  }

  /// Applies full configuration override.
  public func configuration(_ value: FKTextFieldConfiguration) -> Self {
    var copy = self
    copy.configuration = value
    return copy
  }

  /// Applies custom style.
  public func style(_ value: FKTextFieldStyle) -> Self {
    var copy = self
    copy.configuration.style = value
    return copy
  }

  /// Applies custom formatter.
  public func formatter(_ value: FKTextFieldFormatting) -> Self {
    var copy = self
    copy.formatter = value
    return copy
  }

  /// Applies custom sync validator.
  public func validator(_ value: FKTextFieldValidating) -> Self {
    var copy = self
    copy.validator = value
    return copy
  }

  /// Applies custom async validator.
  public func asyncValidator(_ value: FKTextFieldAsyncValidating?) -> Self {
    var copy = self
    copy.asyncValidator = value
    return copy
  }

  /// Builds final text field.
  public func build() -> FKTextField {
    FKTextField(
      configuration: configuration,
      formatter: formatter,
      validator: validator,
      asyncValidator: asyncValidator
    )
  }
}

