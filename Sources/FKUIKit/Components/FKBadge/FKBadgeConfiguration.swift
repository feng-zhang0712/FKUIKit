//
// FKBadgeConfiguration.swift
//

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
  public init(
    backgroundColor: UIColor = .systemRed,
    titleColor: UIColor = .white,
    font: UIFont = .systemFont(ofSize: 11, weight: .semibold),
    borderWidth: CGFloat = 0,
    borderColor: UIColor = .clear,
    horizontalPadding: CGFloat = 5,
    verticalPadding: CGFloat = 2,
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
    self.dotDiameter = dotDiameter
    self.textCornerRadius = textCornerRadius
    self.maxDisplayCount = max(0, maxDisplayCount)
    self.overflowSuffix = overflowSuffix
    self.minimumContentWidth = minimumContentWidth
  }
}

// MARK: - Global defaults

/// Namespace for shared badge defaults and batch visibility helpers.
public enum FKBadge {
  /// Shared defaults applied when creating a `FKBadgeController` without an explicit configuration.
  @MainActor public static var defaultConfiguration = FKBadgeConfiguration()

  /// Hides every badge currently tracked by the registry (see `FKBadgeRegistry`).
  @MainActor public static func hideAllBadges(animated: Bool = false) {
    FKBadgeRegistry.shared.setGlobalSuppressed(true, animated: animated)
  }

  /// Reverses `hideAllBadges()` so each badge reapplies its own visibility rules.
  @MainActor public static func restoreAllBadges(animated: Bool = false) {
    FKBadgeRegistry.shared.setGlobalSuppressed(false, animated: animated)
  }
}
