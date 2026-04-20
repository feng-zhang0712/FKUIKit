//
// FKTextFieldConfiguration.swift
//
// Configuration model for FKTextField.
//

import Foundation
import UIKit

/// Rule set that controls filtering and formatting behavior.
///
/// `FKTextFieldInputRule` is the main entry point for defining how user input is:
/// - filtered (emoji/whitespace/special characters),
/// - formatted (raw vs displayed),
/// - limited (max length),
/// - completed (fixed-length modes).
public struct FKTextFieldInputRule {
  /// Built-in format type.
  public var formatType: FKTextFieldFormatType
  /// Maximum raw text length override.
  ///
  /// If provided, this is applied on the raw value (without separators).
  public var maxLength: Int?
  /// Whether whitespace is allowed.
  ///
  /// Default is `false` to keep raw input stable.
  public var allowsWhitespace: Bool
  /// Whether emoji is allowed.
  ///
  /// Default is `false` to avoid unexpected parsing and storage issues.
  public var allowsEmoji: Bool
  /// Whether special characters are allowed.
  ///
  /// Default is `false`. When disabled, the formatter applies a conservative allowlist.
  public var allowsSpecialCharacters: Bool
  /// Whether the text field should resign first responder automatically when completed.
  ///
  /// This is typically used with fixed-length inputs such as verification codes.
  public var autoDismissKeyboardOnComplete: Bool
  /// Debounce duration for callback notifications.
  ///
  /// Use this to reduce callback frequency when binding to expensive operations.
  public var debounceInterval: TimeInterval
  /// Minimum interval for accepting consecutive edits.
  ///
  /// This can mitigate extremely high-frequency input events in certain environments.
  public var minimumInputInterval: TimeInterval

  /// Creates an input rule.
  public init(
    formatType: FKTextFieldFormatType,
    maxLength: Int? = nil,
    allowsWhitespace: Bool = false,
    allowsEmoji: Bool = false,
    allowsSpecialCharacters: Bool = false,
    autoDismissKeyboardOnComplete: Bool = false,
    debounceInterval: TimeInterval = 0,
    minimumInputInterval: TimeInterval = 0
  ) {
    self.formatType = formatType
    self.maxLength = maxLength
    self.allowsWhitespace = allowsWhitespace
    self.allowsEmoji = allowsEmoji
    self.allowsSpecialCharacters = allowsSpecialCharacters
    self.autoDismissKeyboardOnComplete = autoDismissKeyboardOnComplete
    self.debounceInterval = max(0, debounceInterval)
    self.minimumInputInterval = max(0, minimumInputInterval)
  }
}

/// Full configuration for a text field instance.
///
/// This object bundles all style and behavior options needed to construct a text field
/// that is reusable-list friendly and easy to standardize across a large project.
public struct FKTextFieldConfiguration {
  /// Input rule.
  public var inputRule: FKTextFieldInputRule
  /// Visual style.
  public var style: FKTextFieldStyle
  /// Layout configuration.
  ///
  /// Controls text area height and padding, and how inline messages are laid out.
  public var layout: FKTextFieldLayoutConfiguration
  /// Inline message configuration.
  ///
  /// When enabled, the field renders an inline error label below the text area.
  public var inlineMessage: FKTextFieldInlineMessageConfiguration
  /// Counter configuration.
  ///
  /// When enabled, the field may display a character counter using `rightView`.
  public var counter: FKTextFieldCounterConfiguration
  /// Validation feedback configuration.
  ///
  /// Controls animations such as shake when validation becomes invalid.
  public var validationFeedback: FKTextFieldValidationFeedbackConfiguration
  /// Optional attributed placeholder that has highest priority.
  ///
  /// When non-`nil`, this value overrides `placeholder` and placeholder style properties.
  public var attributedPlaceholder: NSAttributedString?
  /// Placeholder plain text.
  public var placeholder: String?

  /// Creates a full configuration object.
  public init(
    inputRule: FKTextFieldInputRule,
    style: FKTextFieldStyle = .default,
    layout: FKTextFieldLayoutConfiguration = FKTextFieldLayoutConfiguration(),
    inlineMessage: FKTextFieldInlineMessageConfiguration = FKTextFieldInlineMessageConfiguration(),
    counter: FKTextFieldCounterConfiguration = FKTextFieldCounterConfiguration(),
    validationFeedback: FKTextFieldValidationFeedbackConfiguration = FKTextFieldValidationFeedbackConfiguration(),
    attributedPlaceholder: NSAttributedString? = nil,
    placeholder: String? = nil
  ) {
    self.inputRule = inputRule
    self.style = style
    self.layout = layout
    self.inlineMessage = inlineMessage
    self.counter = counter
    self.validationFeedback = validationFeedback
    self.attributedPlaceholder = attributedPlaceholder
    self.placeholder = placeholder
  }
}

