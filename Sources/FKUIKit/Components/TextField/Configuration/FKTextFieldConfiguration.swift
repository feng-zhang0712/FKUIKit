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
  /// Describes an allowlist filter applied before formatting.
  ///
  /// This is useful for simple constraints (numbers/letters/Chinese/alphanumeric) without
  /// needing a dedicated `formatType`.
  public enum AllowedInput: Sendable, Equatable {
    /// Allows any characters (subject to other rule flags like whitespace/emoji).
    case any
    /// Allows digits only.
    case numeric
    /// Allows letters only.
    case alphabetic
    /// Allows Chinese characters only (CJK Unified Ideographs + common extensions).
    case chinese
    /// Allows letters and digits only.
    case alphaNumeric
    /// Allows characters that match the provided *single-character* regex.
    ///
    /// The regex is evaluated per-character, so it should match a single character.
    case regex(String)
  }

  /// Paste policy for the field.
  public enum PastePolicy: Sendable, Equatable {
    /// Allows paste as-is (input will still be filtered/formatted by the pipeline).
    case allow
    /// Disables paste completely.
    case forbid
    /// Allows paste only if the pasted content becomes valid after filtering/formatting.
    case allowIfValid
  }

  /// Return key behavior.
  public enum ReturnKeyBehavior: Sendable, Equatable {
    /// Uses UIKit default behavior.
    case system
    /// Moves focus to the next configured field if available; otherwise dismisses.
    case next
    /// Always dismisses keyboard on return.
    case dismiss
  }

  /// Built-in format type.
  public var formatType: FKTextFieldFormatType
  /// Additional allowlist filter applied before formatting.
  public var allowedInput: AllowedInput
  /// Maximum raw text length override.
  ///
  /// If provided, this is applied on the raw value (without separators).
  public var maxLength: Int?
  /// Minimum raw text length.
  ///
  /// This value is validated by built-in validator and useful for submit-time constraints.
  public var minLength: Int?
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
  /// Paste policy.
  public var pastePolicy: PastePolicy
  /// Return key behavior.
  public var returnKeyBehavior: ReturnKeyBehavior

  /// Creates an input rule.
  public init(
    formatType: FKTextFieldFormatType,
    allowedInput: AllowedInput = .any,
    maxLength: Int? = nil,
    minLength: Int? = nil,
    allowsWhitespace: Bool = false,
    allowsEmoji: Bool = false,
    allowsSpecialCharacters: Bool = false,
    autoDismissKeyboardOnComplete: Bool = false,
    debounceInterval: TimeInterval = 0,
    minimumInputInterval: TimeInterval = 0,
    pastePolicy: PastePolicy = .allow,
    returnKeyBehavior: ReturnKeyBehavior = .system
  ) {
    self.formatType = formatType
    self.allowedInput = allowedInput
    self.maxLength = maxLength
    self.minLength = minLength
    self.allowsWhitespace = allowsWhitespace
    self.allowsEmoji = allowsEmoji
    self.allowsSpecialCharacters = allowsSpecialCharacters
    self.autoDismissKeyboardOnComplete = autoDismissKeyboardOnComplete
    self.debounceInterval = max(0, debounceInterval)
    self.minimumInputInterval = max(0, minimumInputInterval)
    self.pastePolicy = pastePolicy
    self.returnKeyBehavior = returnKeyBehavior
  }
}

/// Controls when and how validation is performed.
public struct FKTextFieldValidationPolicy: Sendable, Equatable {
  /// Validation trigger behavior.
  public var trigger: FKTextFieldValidationTrigger
  /// Debounce interval for validation itself (separate from callback debounce).
  public var debounceInterval: TimeInterval
  /// Whether empty input should be skipped by validator.
  ///
  /// This avoids noisy invalid state before the user starts typing.
  public var ignoresEmptyInput: Bool
  /// Whether async validator result can override sync success into success state.
  public var marksSuccessOnAsyncPass: Bool

  /// Creates a validation policy.
  public init(
    trigger: FKTextFieldValidationTrigger = .onChange,
    debounceInterval: TimeInterval = 0.2,
    ignoresEmptyInput: Bool = true,
    marksSuccessOnAsyncPass: Bool = true
  ) {
    self.trigger = trigger
    self.debounceInterval = max(0, debounceInterval)
    self.ignoresEmptyInput = ignoresEmptyInput
    self.marksSuccessOnAsyncPass = marksSuccessOnAsyncPass
  }
}

/// Controls accessibility behavior and announcements.
public struct FKTextFieldAccessibilityConfiguration: Sendable, Equatable {
  /// Whether status changes should be announced through VoiceOver.
  public var announcesStatusChanges: Bool
  /// Whether counter updates should be announced for screen readers.
  public var announcesCounterChanges: Bool
  /// Minimum tap target width/height for built-in accessory controls.
  public var minimumHitTarget: CGFloat

  /// Creates an accessibility configuration.
  public init(
    announcesStatusChanges: Bool = true,
    announcesCounterChanges: Bool = false,
    minimumHitTarget: CGFloat = 44
  ) {
    self.announcesStatusChanges = announcesStatusChanges
    self.announcesCounterChanges = announcesCounterChanges
    self.minimumHitTarget = max(28, minimumHitTarget)
  }
}

/// Controls animated transitions during visual state updates.
public struct FKTextFieldMotionConfiguration: Sendable, Equatable {
  /// Whether animations are enabled for style transitions.
  public var isEnabled: Bool
  /// Transition duration for border/background changes.
  public var transitionDuration: TimeInterval

  /// Creates a motion configuration.
  public init(
    isEnabled: Bool = true,
    transitionDuration: TimeInterval = 0.2
  ) {
    self.isEnabled = isEnabled
    self.transitionDuration = max(0, transitionDuration)
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
  /// Decoration configuration (border vs underline).
  public var decoration: FKTextFieldDecorationConfiguration
  /// Accessory configuration (clear / password toggle).
  public var accessories: FKTextFieldAccessoryConfiguration
  /// Validation policy.
  public var validationPolicy: FKTextFieldValidationPolicy
  /// Accessibility behavior.
  public var accessibility: FKTextFieldAccessibilityConfiguration
  /// Localization strings.
  public var localization: FKTextFieldLocalization
  /// Motion policy.
  public var motion: FKTextFieldMotionConfiguration
  /// Helper/success/error message channels.
  public var messages: FKTextFieldMessages
  /// Floating label title.
  public var floatingTitle: String?
  /// Read-only mode.
  public var isReadOnly: Bool
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
    decoration: FKTextFieldDecorationConfiguration = FKTextFieldDecorationConfiguration(),
    accessories: FKTextFieldAccessoryConfiguration = FKTextFieldAccessoryConfiguration(),
    validationPolicy: FKTextFieldValidationPolicy = FKTextFieldValidationPolicy(),
    accessibility: FKTextFieldAccessibilityConfiguration = FKTextFieldAccessibilityConfiguration(),
    localization: FKTextFieldLocalization = FKTextFieldLocalization(),
    motion: FKTextFieldMotionConfiguration = FKTextFieldMotionConfiguration(),
    messages: FKTextFieldMessages = FKTextFieldMessages(),
    floatingTitle: String? = nil,
    isReadOnly: Bool = false,
    attributedPlaceholder: NSAttributedString? = nil,
    placeholder: String? = nil
  ) {
    self.inputRule = inputRule
    self.style = style
    self.layout = layout
    self.inlineMessage = inlineMessage
    self.counter = counter
    self.validationFeedback = validationFeedback
    self.decoration = decoration
    self.accessories = accessories
    self.validationPolicy = validationPolicy
    self.accessibility = accessibility
    self.localization = localization
    self.motion = motion
    self.messages = messages
    self.floatingTitle = floatingTitle
    self.isReadOnly = isReadOnly
    self.attributedPlaceholder = attributedPlaceholder
    self.placeholder = placeholder
  }
}

