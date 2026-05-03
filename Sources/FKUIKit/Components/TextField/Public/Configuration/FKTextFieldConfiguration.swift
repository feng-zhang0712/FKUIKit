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

// MARK: - Layout & chrome

/// Layout metrics for `FKTextField` (text rect, intrinsic height, inline message spacing).
public struct FKTextFieldLayoutConfiguration {
  /// Base height for the text input area. Values below `28` are clamped.
  public var textAreaHeight: CGFloat
  /// Insets applied to text and placeholder rects (additive to `UITextField` defaults).
  public var contentInsets: UIEdgeInsets
  /// Vertical gap between the text area and the inline message label.
  public var inlineMessageSpacing: CGFloat

  public init(
    textAreaHeight: CGFloat = 44,
    contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12),
    inlineMessageSpacing: CGFloat = 6
  ) {
    self.textAreaHeight = max(28, textAreaHeight)
    self.contentInsets = contentInsets
    self.inlineMessageSpacing = max(0, inlineMessageSpacing)
  }
}

/// Inline helper / error / success label under the field.
public struct FKTextFieldInlineMessageConfiguration {
  public var showsErrorMessage: Bool
  public var errorFont: UIFont
  public var errorColor: UIColor
  public var helperFont: UIFont
  public var helperColor: UIColor
  public var successColor: UIColor

  public init(
    showsErrorMessage: Bool = false,
    errorFont: UIFont = .preferredFont(forTextStyle: .caption1),
    errorColor: UIColor = .systemRed,
    helperFont: UIFont = .preferredFont(forTextStyle: .caption1),
    helperColor: UIColor = .secondaryLabel,
    successColor: UIColor = .systemGreen
  ) {
    self.showsErrorMessage = showsErrorMessage
    self.errorFont = errorFont
    self.errorColor = errorColor
    self.helperFont = helperFont
    self.helperColor = helperColor
    self.successColor = successColor
  }
}

/// Trailing character counter (`current` / `max`).
public struct FKTextFieldCounterConfiguration {
  /// When enabled, shows a counter in the trailing accessory stack (see README for `rightView` interaction).
  public var isEnabled: Bool
  public var maxCount: Int?
  public var font: UIFont
  public var color: UIColor

  public init(
    isEnabled: Bool = false,
    maxCount: Int? = nil,
    font: UIFont = .preferredFont(forTextStyle: .caption2),
    color: UIColor = .secondaryLabel
  ) {
    self.isEnabled = isEnabled
    self.maxCount = maxCount
    self.font = font
    self.color = color
  }
}

/// Visual-only feedback when validation fails (e.g. shake).
public struct FKTextFieldValidationFeedbackConfiguration {
  public var shakesOnInvalid: Bool
  public var shakeAmplitude: CGFloat
  public var shakeCount: Int
  public var shakeDuration: TimeInterval

  public init(
    shakesOnInvalid: Bool = false,
    shakeAmplitude: CGFloat = 10,
    shakeCount: Int = 4,
    shakeDuration: TimeInterval = 0.35
  ) {
    self.shakesOnInvalid = shakesOnInvalid
    self.shakeAmplitude = shakeAmplitude
    self.shakeCount = shakeCount
    self.shakeDuration = shakeDuration
  }
}

/// Border versus underline decoration.
public struct FKTextFieldDecorationConfiguration: @unchecked Sendable {
  public enum Mode: @unchecked Sendable, Equatable {
    case border
    case underline(thickness: CGFloat, insets: UIEdgeInsets)
  }

  public var mode: Mode

  public init(mode: Mode = .border) {
    self.mode = mode
  }
}

/// Built-in clear control (trailing accessory).
public struct FKTextFieldClearButtonConfiguration: @unchecked Sendable {
  public var isEnabled: Bool
  public var image: UIImage?
  public var accessibilityLabel: String
  public var resignsFirstResponderOnTap: Bool

  public init(
    isEnabled: Bool = true,
    image: UIImage? = nil,
    accessibilityLabel: String = "Clear text",
    resignsFirstResponderOnTap: Bool = false
  ) {
    self.isEnabled = isEnabled
    self.image = image
    self.accessibilityLabel = accessibilityLabel
    self.resignsFirstResponderOnTap = resignsFirstResponderOnTap
  }
}

/// Built-in password visibility toggle (password format only).
public struct FKTextFieldPasswordToggleConfiguration: @unchecked Sendable {
  public var isEnabled: Bool
  public var hiddenImage: UIImage?
  public var visibleImage: UIImage?
  public var accessibilityLabel: String

  public init(
    isEnabled: Bool = true,
    hiddenImage: UIImage? = nil,
    visibleImage: UIImage? = nil,
    accessibilityLabel: String = "Toggle password visibility"
  ) {
    self.isEnabled = isEnabled
    self.hiddenImage = hiddenImage
    self.visibleImage = visibleImage
    self.accessibilityLabel = accessibilityLabel
  }
}

public enum FKTextFieldAccessoryTintBehavior: Sendable, Equatable {
  case fixed
  case followsBorderState
}

/// AutoFill, keyboard return key, capitalization, and optional password rules.
///
/// When fields are `nil`, defaults are inferred from `FKTextFieldInputRule.formatType` and
/// `returnKeyBehavior`. Override for sign-up (`.newPassword`, `passwordRules`) or paired
/// `.username` / `.password` AutoFill.
public struct FKTextFieldTextInputTraitsConfiguration: @unchecked Sendable {
  public var textContentType: UITextContentType?
  public var returnKeyType: UIReturnKeyType?
  public var autocapitalizationType: UITextAutocapitalizationType?
  public var keyboardAppearance: UIKeyboardAppearance?
  public var passwordRules: UITextInputPasswordRules?

  public init(
    textContentType: UITextContentType? = nil,
    returnKeyType: UIReturnKeyType? = nil,
    autocapitalizationType: UITextAutocapitalizationType? = nil,
    keyboardAppearance: UIKeyboardAppearance? = nil,
    passwordRules: UITextInputPasswordRules? = nil
  ) {
    self.textContentType = textContentType
    self.returnKeyType = returnKeyType
    self.autocapitalizationType = autocapitalizationType
    self.keyboardAppearance = keyboardAppearance
    self.passwordRules = passwordRules
  }
}

/// Trailing accessories: clear, counter, password toggle.
public struct FKTextFieldAccessoryConfiguration: @unchecked Sendable {
  public var clearButton: FKTextFieldClearButtonConfiguration
  public var passwordToggle: FKTextFieldPasswordToggleConfiguration
  public var spacing: CGFloat
  public var iconSize: CGFloat
  public var horizontalPadding: CGFloat
  public var tintBehavior: FKTextFieldAccessoryTintBehavior

  public init(
    clearButton: FKTextFieldClearButtonConfiguration = FKTextFieldClearButtonConfiguration(),
    passwordToggle: FKTextFieldPasswordToggleConfiguration = FKTextFieldPasswordToggleConfiguration(),
    spacing: CGFloat = 6,
    iconSize: CGFloat = 14,
    horizontalPadding: CGFloat = 8,
    tintBehavior: FKTextFieldAccessoryTintBehavior = .fixed
  ) {
    self.clearButton = clearButton
    self.passwordToggle = passwordToggle
    self.spacing = max(0, spacing)
    self.iconSize = max(10, iconSize)
    self.horizontalPadding = max(0, horizontalPadding)
    self.tintBehavior = tintBehavior
  }
}

// MARK: - Aggregate configuration

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
  /// System text input traits (AutoFill, return key, capitalization, password rules).
  public var textInputTraits: FKTextFieldTextInputTraitsConfiguration
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
    textInputTraits: FKTextFieldTextInputTraitsConfiguration = FKTextFieldTextInputTraitsConfiguration(),
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
    self.textInputTraits = textInputTraits
    self.messages = messages
    self.floatingTitle = floatingTitle
    self.isReadOnly = isReadOnly
    self.attributedPlaceholder = attributedPlaceholder
    self.placeholder = placeholder
  }
}

