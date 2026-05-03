import Foundation

/// Formatter protocol used by `FKTextField`.
///
/// Conform to this protocol to provide custom formatting (e.g. business-specific grouping,
/// masking, or locale-aware behavior) without modifying the core text field.
public protocol FKTextFieldFormatting {
  /// Formats the provided text using the rule.
  ///
  /// - Parameters:
  ///   - text: Source text in current display form.
  ///   - rule: Active input rule.
  /// - Returns: A formatting result that includes raw and display text.
  func format(text: String, rule: FKTextFieldInputRule) -> FKTextFieldFormattingResult
}

/// Validator protocol used by `FKTextField`.
///
/// Conform to this protocol to provide custom validation rules (e.g. server-driven checks,
/// complex domain constraints) while keeping `FKTextField` testable and pluggable.
public protocol FKTextFieldValidating {
  /// Validates the text under the active rule.
  ///
  /// - Parameters:
  ///   - rawText: Text without separators.
  ///   - formattedText: Text displayed in UI.
  ///   - rule: Active input rule.
  /// - Returns: Validation result.
  func validate(
    rawText: String,
    formattedText: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult
}

/// API contract for configurable custom text fields.
///
/// This protocol exists to keep configuration APIs consistent across `UITextField`/`UITextView`
/// variants and to simplify dependency injection in larger codebases.
@MainActor
public protocol FKTextFieldConfigurable: AnyObject {
  /// Applies a full configuration.
  func configure(_ configuration: FKTextFieldConfiguration)
}

/// Unified raw-text API for ``FKTextField`` and ``FKCountTextView``.
///
/// The `fk_` prefix matches other FKUIKit extensions and avoids clashing with UIKit selectors.
@MainActor
public protocol FKTextInputComponent: AnyObject {
  var fk_rawText: String { get }
  func fk_setText(_ text: String)
  func fk_clear()
}

