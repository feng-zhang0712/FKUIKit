//
// FKTextFieldBehaviorConfiguration.swift
//
// Behavior and layout configurations for FKTextField.
//

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

  /// Creates an inline message configuration.
  public init(
    showsErrorMessage: Bool = false,
    errorFont: UIFont = .preferredFont(forTextStyle: .caption1),
    errorColor: UIColor = .systemRed
  ) {
    self.showsErrorMessage = showsErrorMessage
    self.errorFont = errorFont
    self.errorColor = errorColor
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

