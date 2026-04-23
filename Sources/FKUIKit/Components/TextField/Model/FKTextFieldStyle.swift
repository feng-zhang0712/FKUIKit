import UIKit

/// Visual style for a specific `FKTextField` state.
///
/// This model describes the layer-level appearance of the input surface, including:
/// border, corner radius, background, and optional shadow.
public struct FKTextFieldStateStyle {
  /// Border color.
  public var borderColor: UIColor
  /// Border width.
  ///
  /// Default is `1`. Values less than `0` are not meaningful.
  public var borderWidth: CGFloat
  /// Corner radius.
  ///
  /// Default is `10`.
  public var cornerRadius: CGFloat
  /// Background color.
  ///
  /// Default is `secondarySystemBackground`.
  public var backgroundColor: UIColor
  /// Optional shadow color.
  public var shadowColor: UIColor?
  /// Shadow opacity.
  ///
  /// Use `0` to disable shadow.
  public var shadowOpacity: Float
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Shadow blur radius.
  ///
  /// Maps to `CALayer.shadowRadius`.
  public var shadowRadius: CGFloat

  /// Creates a state style.
  public init(
    borderColor: UIColor,
    borderWidth: CGFloat = 1,
    cornerRadius: CGFloat = 10,
    backgroundColor: UIColor = .secondarySystemBackground,
    shadowColor: UIColor? = nil,
    shadowOpacity: Float = 0,
    shadowOffset: CGSize = .zero,
    shadowRadius: CGFloat = 0
  ) {
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.shadowColor = shadowColor
    self.shadowOpacity = shadowOpacity
    self.shadowOffset = shadowOffset
    self.shadowRadius = shadowRadius
  }
}

/// Full style group for normal/focused/error states.
///
/// `FKTextField` switches between these styles automatically based on focus and
/// validation state.
public struct FKTextFieldStyle {
  /// Style used in normal state.
  public var normal: FKTextFieldStateStyle
  /// Style used while editing.
  public var focused: FKTextFieldStateStyle
  /// Style used in invalid/error state.
  public var error: FKTextFieldStateStyle
  /// Style used in success state.
  public var success: FKTextFieldStateStyle
  /// Style used when content is non-empty and not focused.
  public var filled: FKTextFieldStateStyle
  /// Style used when the field is disabled (`isEnabled == false`).
  public var disabled: FKTextFieldStateStyle
  /// Style used for read-only state.
  public var readOnly: FKTextFieldStateStyle
  /// Text color.
  public var textColor: UIColor
  /// Text font.
  public var font: UIFont
  /// Placeholder color.
  public var placeholderColor: UIColor
  /// Placeholder font.
  public var placeholderFont: UIFont
  /// Floating title color.
  public var floatingTitleColor: UIColor
  /// Floating title font.
  public var floatingTitleFont: UIFont

  /// Creates a style group.
  public init(
    normal: FKTextFieldStateStyle,
    focused: FKTextFieldStateStyle,
    error: FKTextFieldStateStyle,
    success: FKTextFieldStateStyle,
    filled: FKTextFieldStateStyle,
    disabled: FKTextFieldStateStyle,
    readOnly: FKTextFieldStateStyle,
    textColor: UIColor = .label,
    font: UIFont = .systemFont(ofSize: 16),
    placeholderColor: UIColor = .secondaryLabel,
    placeholderFont: UIFont = .systemFont(ofSize: 16),
    floatingTitleColor: UIColor = .secondaryLabel,
    floatingTitleFont: UIFont = .preferredFont(forTextStyle: .caption1)
  ) {
    self.normal = normal
    self.focused = focused
    self.error = error
    self.success = success
    self.filled = filled
    self.disabled = disabled
    self.readOnly = readOnly
    self.textColor = textColor
    self.font = font
    self.placeholderColor = placeholderColor
    self.placeholderFont = placeholderFont
    self.floatingTitleColor = floatingTitleColor
    self.floatingTitleFont = floatingTitleFont
  }
}

public extension FKTextFieldStyle {
  /// Default style.
  ///
  /// This is intended as a sensible baseline and can be customized globally via
  /// `FKTextFieldManager.shared.defaultStyle` or per-instance via configuration.
  static var `default`: FKTextFieldStyle {
    FKTextFieldStyle(
      normal: FKTextFieldStateStyle(borderColor: .separator),
      focused: FKTextFieldStateStyle(borderColor: .systemBlue),
      error: FKTextFieldStateStyle(borderColor: .systemRed),
      success: FKTextFieldStateStyle(borderColor: .systemGreen),
      filled: FKTextFieldStateStyle(borderColor: .systemGray3),
      disabled: FKTextFieldStateStyle(
        borderColor: .systemGray4,
        borderWidth: 1,
        cornerRadius: 10,
        backgroundColor: .tertiarySystemBackground
      ),
      readOnly: FKTextFieldStateStyle(
        borderColor: .systemGray3,
        borderWidth: 1,
        cornerRadius: 10,
        backgroundColor: .secondarySystemBackground
      ),
      textColor: .label,
      font: .systemFont(ofSize: 16),
      placeholderColor: .secondaryLabel,
      placeholderFont: .systemFont(ofSize: 16),
      floatingTitleColor: .secondaryLabel,
      floatingTitleFont: .preferredFont(forTextStyle: .caption1)
    )
  }
}

