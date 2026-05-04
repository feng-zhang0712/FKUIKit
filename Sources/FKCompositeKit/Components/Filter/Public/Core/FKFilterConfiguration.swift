import UIKit

/// Chevron tab strip typography, spacing, and title/chevron colors for ``FKFilterTab`` / ``FKFilterController``.
///
/// Maps to ``FKAnchoredDropdownTab/chevronTitle(id:itemID:title:subtitle:normalTitleColor:expandedTitleColor:normalChevronColor:expandedChevronColor:titleFont:subtitleFont:chevronSize:chevronSpacing:titleSubtitleSpacing:content:)``.
///
/// Per-tab overrides live on ``FKFilterTab/tabStrip``; when `nil`, ``FKFilterConfiguration/defaultTabStrip`` is used.
public struct FKFilterTabStripConfiguration: Sendable {
  public var titleTextStyle: UIFont.TextStyle
  public var subtitleTextStyle: UIFont.TextStyle
  public var chevronSize: CGSize
  public var chevronSpacing: CGFloat
  public var titleSubtitleSpacing: CGFloat
  public var normalTitleColor: UIColor
  public var expandedTitleColor: UIColor
  public var normalChevronColor: UIColor
  public var expandedChevronColor: UIColor

  public init(
    titleTextStyle: UIFont.TextStyle = .subheadline,
    subtitleTextStyle: UIFont.TextStyle = .caption2,
    chevronSize: CGSize = CGSize(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2,
    normalTitleColor: UIColor = .label,
    expandedTitleColor: UIColor = .tintColor,
    normalChevronColor: UIColor = .secondaryLabel,
    expandedChevronColor: UIColor = .tintColor
  ) {
    self.titleTextStyle = titleTextStyle
    self.subtitleTextStyle = subtitleTextStyle
    self.chevronSize = chevronSize
    self.chevronSpacing = chevronSpacing
    self.titleSubtitleSpacing = titleSubtitleSpacing
    self.normalTitleColor = normalTitleColor
    self.expandedTitleColor = expandedTitleColor
    self.normalChevronColor = normalChevronColor
    self.expandedChevronColor = expandedChevronColor
  }
}

/// Top-level settings for ``FKFilterController``: anchored dropdown shell, strip defaults, panel chrome defaults, and lifecycle hooks.
///
/// Panel **content** (two-column models, chips, list styles, etc.) stays on ``FKFilterPanelFactory`` / per-panel `Configuration`
/// types so each panel kind can evolve independently.
public struct FKFilterConfiguration<TabID: Hashable> {
  /// Dropdown + tab bar behavior (backdrop, switch animation, caching, anchor placement, …).
  public var anchoredDropdown: FKAnchoredDropdownConfiguration

  /// Optional transitions and state hooks on the anchored dropdown.
  public var anchoredEvents: FKAnchoredDropdownConfiguration.Events<TabID>

  /// Used when ``FKFilterTab/tabStrip`` is `nil`.
  public var defaultTabStrip: FKFilterTabStripConfiguration

  /// Passed to ``FKFilterPanelFactory/loadingTitle`` when you build the factory with these values.
  public var panelLoadingTitle: String

  /// Passed to ``FKFilterPanelFactory/wrapsPanelWithTopHairline`` when you build the factory with these values.
  public var wrapsPanelWithTopHairline: Bool

  public init(
    anchoredDropdown: FKAnchoredDropdownConfiguration = .default,
    anchoredEvents: FKAnchoredDropdownConfiguration.Events<TabID> = .init(),
    defaultTabStrip: FKFilterTabStripConfiguration = .init(),
    panelLoadingTitle: String = "Loading...",
    wrapsPanelWithTopHairline: Bool = true
  ) {
    self.anchoredDropdown = anchoredDropdown
    self.anchoredEvents = anchoredEvents
    self.defaultTabStrip = defaultTabStrip
    self.panelLoadingTitle = panelLoadingTitle
    self.wrapsPanelWithTopHairline = wrapsPanelWithTopHairline
  }
}
