import UIKit

/// Visual defaults for a badge instance. Copy-on-write style: assign into `FKBadgeController` to update appearance.
public struct FKBadgeConfiguration: Equatable {
  /// Fill behind the label (or dot).
  public var backgroundColor: UIColor
  /// Title color for numeric / text badges.
  public var titleColor: UIColor
  /// Font for numeric and text badges (ignored for dot-only mode).
  public var font: UIFont

  /// Stroke around the badge; use `0` for no border.
  public var borderWidth: CGFloat
  public var borderColor: UIColor

  /// Horizontal inset around the label (dot mode ignores horizontal padding for sizing).
  public var horizontalPadding: CGFloat
  /// Vertical inset around the label.
  public var verticalPadding: CGFloat
  /// Extra kerning for number/text glyph spacing.
  public var textKerning: CGFloat

  /// Diameter for pure dot mode.
  public var dotDiameter: CGFloat

  /// When non-`nil`, used as the layer corner radius for text badges. `nil` uses half of the view height (pill).
  public var textCornerRadius: CGFloat?

  /// Inclusive upper bound before switching to `"\(maxDisplayCount)\(overflowSuffix)"`.
  public var maxDisplayCount: Int
  /// Appended after `maxDisplayCount` (typically `"+"`).
  public var overflowSuffix: String

  /// Minimum layout width for numeric / text content (prevents ultra-narrow badges). `nil` uses height (pill cap).
  public var minimumContentWidth: CGFloat?

  /// Creates a configuration; defaults match typical iOS numeric badges (system red, white label, 99+ overflow).
  ///
  /// - Parameters:
  ///   - backgroundColor: Badge fill color. Default is `.systemRed`.
  ///   - titleColor: Foreground text color. Default is `.white`.
  ///   - font: Text font used for numeric/text mode.
  ///   - borderWidth: Border width in points. `0` disables border.
  ///   - borderColor: Border color.
  ///   - horizontalPadding: Horizontal content inset for text mode.
  ///   - verticalPadding: Vertical content inset for text mode.
  ///   - textKerning: Character spacing for text mode.
  ///   - dotDiameter: Fixed size for dot mode.
  ///   - textCornerRadius: Optional explicit corner radius for text mode; `nil` means pill radius.
  ///   - maxDisplayCount: Overflow threshold (inclusive). Values below `0` are clamped to `0`.
  ///   - overflowSuffix: Overflow suffix appended after `maxDisplayCount` (for example `"+"`).
  ///   - minimumContentWidth: Optional lower bound width for text/number mode.
  public init(
    backgroundColor: UIColor = .systemRed,
    titleColor: UIColor = .white,
    font: UIFont = .systemFont(ofSize: 11, weight: .semibold),
    borderWidth: CGFloat = 0,
    borderColor: UIColor = .clear,
    horizontalPadding: CGFloat = 5,
    verticalPadding: CGFloat = 2,
    textKerning: CGFloat = 0,
    dotDiameter: CGFloat = 8,
    textCornerRadius: CGFloat? = nil,
    maxDisplayCount: Int = 99,
    overflowSuffix: String = "+",
    minimumContentWidth: CGFloat? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.titleColor = titleColor
    self.font = font
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.horizontalPadding = horizontalPadding
    self.verticalPadding = verticalPadding
    self.textKerning = textKerning
    self.dotDiameter = dotDiameter
    self.textCornerRadius = textCornerRadius
    self.maxDisplayCount = max(0, maxDisplayCount)
    self.overflowSuffix = overflowSuffix
    self.minimumContentWidth = minimumContentWidth
  }
}

// MARK: - Global defaults

/// Namespace for shared badge defaults and batch visibility helpers.
@MainActor
public enum FKBadge {
  /// Shared defaults applied when creating a `FKBadgeController` without an explicit configuration.
  ///
  /// Update this at app launch to define project-wide badge baseline style.
  public static var defaultConfiguration = FKBadgeConfiguration()

  /// Hides every badge currently tracked by the registry (see `FKBadgeRegistry`).
  ///
  /// - Parameter animated: Whether each badge should animate hide transition.
  public static func hideAllBadges(animated: Bool = false) {
    FKBadgeRegistry.shared.setGlobalSuppressed(true, animated: animated)
  }

  /// Reverses `hideAllBadges()` so each badge reapplies its own visibility rules.
  ///
  /// - Parameter animated: Whether each badge should animate restore transition.
  public static func restoreAllBadges(animated: Bool = false) {
    FKBadgeRegistry.shared.setGlobalSuppressed(false, animated: animated)
  }
}
