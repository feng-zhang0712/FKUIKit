import UIKit

/// Visual style for "pill" options used across filter panels.
///
/// This is intentionally generic and is used by:
/// - `FKFilterChipsViewController` (chip grid)
/// - `FKFilterTwoColumnGridViewController` (right-side grid items)
///
/// If you need a chips-only style, wrap this type in your own configuration rather than introducing
/// a new cross-cutting style type inside this module.
public struct FKFilterPillStyle {
  public var font: UIFont
  public var cornerRadius: CGFloat
  public var contentInsets: UIEdgeInsets
  public var normalTextColor: UIColor
  public var selectedTextColor: UIColor
  public var disabledTextColor: UIColor
  public var normalBackgroundColor: UIColor
  public var selectedBackgroundColor: UIColor
  public var disabledBackgroundColor: UIColor
  public var normalBorderColor: UIColor
  public var selectedBorderColor: UIColor
  public var disabledBorderColor: UIColor
  public var disabledAlpha: CGFloat

  public init(
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    cornerRadius: CGFloat = 6,
    contentInsets: UIEdgeInsets = .init(top: 10, left: 12, bottom: 10, right: 12),
    normalTextColor: UIColor = .label,
    selectedTextColor: UIColor = .systemRed,
    disabledTextColor: UIColor = .secondaryLabel,
    normalBackgroundColor: UIColor = .systemBackground,
    selectedBackgroundColor: UIColor = UIColor.systemRed.withAlphaComponent(0.10),
    disabledBackgroundColor: UIColor = .systemGray6,
    normalBorderColor: UIColor = .separator,
    selectedBorderColor: UIColor = UIColor.systemRed.withAlphaComponent(0.55),
    disabledBorderColor: UIColor = .separator,
    disabledAlpha: CGFloat = 0.6
  ) {
    self.font = font
    self.cornerRadius = cornerRadius
    self.contentInsets = contentInsets
    self.normalTextColor = normalTextColor
    self.selectedTextColor = selectedTextColor
    self.disabledTextColor = disabledTextColor
    self.normalBackgroundColor = normalBackgroundColor
    self.selectedBackgroundColor = selectedBackgroundColor
    self.disabledBackgroundColor = disabledBackgroundColor
    self.normalBorderColor = normalBorderColor
    self.selectedBorderColor = selectedBorderColor
    self.disabledBorderColor = disabledBorderColor
    self.disabledAlpha = disabledAlpha
  }
}


