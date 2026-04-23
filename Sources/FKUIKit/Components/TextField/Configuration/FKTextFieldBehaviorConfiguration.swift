import UIKit

/// Layout configuration for `FKTextField`.
///
/// This configuration affects only layout (rects and intrinsic size), not formatting logic.
public struct FKTextFieldLayoutConfiguration {
  /// Base height for the text input area.
  ///
  /// Values less than `28` are clamped to keep the control usable.
  public var textAreaHeight: CGFloat
  /// Insets applied to text/placeholder rects.
  ///
  /// These insets are applied on top of `UITextField` default rect calculations.
  public var contentInsets: UIEdgeInsets
  /// Spacing between text area and inline message label.
  public var inlineMessageSpacing: CGFloat

  /// Creates a layout configuration.
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

/// Controls inline validation message rendering.
///
/// This is intentionally separate from validation rules so UI can be enabled/disabled
/// without changing business logic.
public struct FKTextFieldInlineMessageConfiguration {
  /// Enables an inline error label below the text area.
  public var showsErrorMessage: Bool
  /// Font used by the inline error label.
  public var errorFont: UIFont
  /// Color used by the inline error label.
  public var errorColor: UIColor
  /// Font used by helper/success text.
  public var helperFont: UIFont
  /// Color used for helper text.
  public var helperColor: UIColor
  /// Color used for success text.
  public var successColor: UIColor

  /// Creates an inline message configuration.
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

/// Controls realtime character counting behavior.
///
/// The counter is designed for lightweight UX feedback. For strict enforcement, use
/// `inputRule.maxLength` and/or custom validators.
public struct FKTextFieldCounterConfiguration {
  /// Enables a right-side counter label (`count/max`).
  ///
  /// - Important: The counter occupies `rightView` when enabled and when there is no
  ///   custom `rightView` and the format type is not `.password`.
  public var isEnabled: Bool
  /// Optional max count override. If `nil`, uses `inputRule.maxLength` when available.
  public var maxCount: Int?
  /// Font used by the counter label.
  public var font: UIFont
  /// Text color used by the counter label.
  public var color: UIColor

  /// Creates a counter configuration.
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

/// Validation feedback configuration.
///
/// This configuration only affects visual feedback, not validation decisions.
public struct FKTextFieldValidationFeedbackConfiguration {
  /// Automatically shakes the text field when validation becomes invalid.
  public var shakesOnInvalid: Bool
  /// Shake amplitude in points.
  ///
  /// Larger values result in a more noticeable shake.
  public var shakeAmplitude: CGFloat
  /// Number of shakes.
  ///
  /// This represents back-and-forth oscillations.
  public var shakeCount: Int
  /// Total duration.
  ///
  /// Shorter durations produce a snappier effect.
  public var shakeDuration: TimeInterval

  /// Creates a feedback configuration.
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

/// Controls how the input surface is decorated (border vs underline).
public struct FKTextFieldDecorationConfiguration: @unchecked Sendable {
  /// Presentation mode for the input surface.
  public enum Mode: @unchecked Sendable, Equatable {
    /// Uses `CALayer` border and corner radius.
    case border
    /// Renders a bottom underline.
    ///
    /// The underline color can be driven by state styles, and the thickness/insets
    /// are controlled by the associated values.
    case underline(thickness: CGFloat, insets: UIEdgeInsets)
  }

  /// Decoration mode.
  public var mode: Mode

  /// Creates a decoration configuration.
  public init(
    mode: Mode = .border
  ) {
    self.mode = mode
  }
}

/// Controls the built-in clear button behavior.
public struct FKTextFieldClearButtonConfiguration: @unchecked Sendable {
  /// Whether the clear button is enabled.
  public var isEnabled: Bool
  /// Image used by the clear button. When `nil`, a default SF Symbol is used.
  public var image: UIImage?
  /// Accessibility label for the clear button.
  public var accessibilityLabel: String
  /// Whether tapping the clear button resigns first responder.
  public var resignsFirstResponderOnTap: Bool

  /// Creates a clear button configuration.
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

/// Controls the built-in password toggle button behavior.
public struct FKTextFieldPasswordToggleConfiguration: @unchecked Sendable {
  /// Whether the toggle button is enabled in password mode.
  public var isEnabled: Bool
  /// Image used when password is hidden. When `nil`, a default SF Symbol is used.
  public var hiddenImage: UIImage?
  /// Image used when password is visible. When `nil`, a default SF Symbol is used.
  public var visibleImage: UIImage?
  /// Accessibility label for the toggle.
  public var accessibilityLabel: String

  /// Creates a password toggle configuration.
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

/// Controls trailing accessory views (clear / counter / password toggle).
public enum FKTextFieldAccessoryTintBehavior: Sendable, Equatable {
  /// Accessory icons use `style.placeholderColor` and do not react to border state.
  case fixed
  /// Accessory icons follow the current border color of normal/focused/error/disabled state.
  case followsBorderState
}

/// Controls trailing accessory views (clear / counter / password toggle).
public struct FKTextFieldAccessoryConfiguration: @unchecked Sendable {
  /// Clear button configuration.
  public var clearButton: FKTextFieldClearButtonConfiguration
  /// Password toggle configuration.
  public var passwordToggle: FKTextFieldPasswordToggleConfiguration
  /// Spacing between accessory items.
  public var spacing: CGFloat
  /// Base icon size for built-in clear/toggle symbols.
  public var iconSize: CGFloat
  /// Extra horizontal padding between accessory group and field border.
  public var horizontalPadding: CGFloat
  /// Icon tint behavior against state changes.
  public var tintBehavior: FKTextFieldAccessoryTintBehavior

  /// Creates an accessory configuration.
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

