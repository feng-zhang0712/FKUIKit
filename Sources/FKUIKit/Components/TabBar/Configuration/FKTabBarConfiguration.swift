import UIKit

// MARK: - Layout

/// Item content layout direction.
public enum FKTabBarItemLayoutDirection: Equatable {
  /// Horizontal content layout.
  case horizontal
  /// Vertical content layout.
  case vertical
}

/// RTL handling policy for visual layout.
public enum FKTabBarRTLBehavior: Equatable {
  /// Follows `traitCollection.layoutDirection`.
  case automatic
  /// Forces left-to-right layout.
  case forceLeftToRight
  /// Forces right-to-left layout.
  case forceRightToLeft
}

/// Width strategy for tab items.
public enum FKTabBarItemWidthMode: Equatable {
  /// Use intrinsic size from content measurement.
  ///
  /// Best for scrollable strips and mixed text lengths.
  case intrinsic
  /// Fixed width for each item.
  case fixed(CGFloat)
  /// Split available width equally across visible items.
  ///
  /// Commonly used for non-scrollable, segmented layouts.
  case fillEqually
  /// Intrinsic width constrained by minimum and maximum values.
  case constrained(min: CGFloat, max: CGFloat)
}

/// Positioning strategy when auto-scrolling selected item into view.
public enum FKTabBarSelectionScrollPosition: Equatable {
  /// Keep selected item near center.
  ///
  /// Produces a stable focus point during repeated selection changes.
  case center
  /// Align selected item to leading edge.
  case leading
  /// Align selected item to trailing edge.
  case trailing
  /// Scroll minimally to make target fully visible.
  ///
  /// Reduces motion and preserves nearby context.
  case minimalVisible
}

/// Animation curve for selection scroll.
public enum FKTabBarScrollAnimationCurve: Equatable {
  case easeInOut
  case easeIn
  case easeOut
  case linear
}

/// Selection scroll animation configuration.
public struct FKTabBarSelectionScrollAnimation: Equatable {
  /// Whether animated scrolling is enabled.
  public var isEnabled: Bool
  /// Duration used when `isEnabled` is true. Default is `0.25`.
  public var duration: TimeInterval
  /// Curve used when `isEnabled` is true.
  public var curve: FKTabBarScrollAnimationCurve

  public init(isEnabled: Bool = true, duration: TimeInterval = 0.25, curve: FKTabBarScrollAnimationCurve = .easeInOut) {
    self.isEnabled = isEnabled
    self.duration = duration
    self.curve = curve
  }
}

/// Title overflow strategy for tab labels.
public enum FKTabBarTitleOverflowMode: Equatable {
  /// Truncate tail when space is insufficient.
  case truncate
  /// Allow font to shrink within `minimumScaleFactor`.
  case shrink(minimumScaleFactor: CGFloat)
  /// Wrap title onto multiple lines.
  ///
  /// The actual maximum line count is resolved by layout policy (for example Dynamic Type strategy).
  case wrap
  /// Use intrinsic width; tab bar may become scrollable.
  case automaticWidth
  /// Enforce fixed width for each tab.
  case fixedWidth(CGFloat)
}

/// Layout behavior policy when Dynamic Type grows into accessibility categories.
public enum FKTabBarLargeTextLayoutStrategy: Equatable {
  /// Keep `titleOverflowMode` and typography defaults unchanged.
  case automatic
  /// Force single-line truncation in accessibility categories.
  case truncate
  /// Force single-line shrinking in accessibility categories.
  case shrink(minimumScaleFactor: CGFloat)
  /// Force wrapping to the configured maximum line count.
  case wrap(maxLines: Int)
  /// Force wrapping and allow the tab bar to advertise a taller intrinsic height.
  case wrapAndIncreaseHeight(maxLines: Int)
}

/// Height policy for `FKTabBar` when resolving its intrinsic height.
public enum FKTabBarSafeAreaHeightPolicy: Equatable {
  /// `preferredBarHeight` is treated as visual bar height and excludes bottom safe area.
  ///
  /// This is suitable when the host already handles container-safe-area outside the tab bar.
  case excludeBottomSafeArea
  /// Adds `safeAreaInsets.bottom` on top of `preferredBarHeight`.
  ///
  /// This is suitable for bottom-docked tab bars that should naturally clear the home indicator.
  case includeBottomSafeArea
}

/// Content alignment behavior for intrinsic-width tab items when there is extra horizontal space.
///
/// This strategy is only evaluated when:
/// - `widthMode != .fillEqually`, and
/// - total item content width is smaller than the available strip width.
///
/// In all other cases (for example `fillEqually`, or content wider than container), layout falls back
/// to width/scroll rules and this alignment is ignored.
public enum FKTabBarContentAlignment: Equatable {
  /// Pack items toward logical leading edge in the current layout direction.
  ///
  /// Under RTL this maps to the visual right edge.
  case leading
  /// Pack items toward logical trailing edge in the current layout direction.
  ///
  /// Under RTL this maps to the visual left edge.
  case trailing
  /// Pack items as a group and center the group.
  case center
  /// Distribute remaining space between adjacent items.
  case spaceBetween
  /// Distribute remaining space around each item (half-space at both ends).
  case spaceAround
  /// Distribute remaining space evenly, including both ends.
  case spaceEvenly
}

/// Layout configuration for `FKTabBar`.
public struct FKTabBarLayoutConfiguration {
  /// Runtime spacing context for custom spacing strategies.
  public struct SpacingContext {
    /// Number of currently visible tab items.
    public let visibleItemsCount: Int
    /// Whether strip scrolling is enabled.
    public let isScrollable: Bool
    /// Baseline spacing configured by `itemSpacing`.
    public let defaultSpacing: CGFloat

    public init(visibleItemsCount: Int, isScrollable: Bool, defaultSpacing: CGFloat) {
      self.visibleItemsCount = visibleItemsCount
      self.isScrollable = isScrollable
      self.defaultSpacing = defaultSpacing
    }
  }

  /// Whether the tab list can scroll horizontally.
  ///
  /// When `false`, width strategy and alignment should typically avoid overflow.
  public var isScrollable: Bool
  /// Item spacing.
  public var itemSpacing: CGFloat
  /// Optional custom spacing provider.
  ///
  /// Return `nil` to fall back to `itemSpacing`. This closure is evaluated during layout passes,
  /// so it should be pure and allocation-light.
  public var customSpacingProvider: ((_ context: SpacingContext) -> CGFloat?)?
  /// Content insets.
  ///
  /// Insets affect both visual padding and available width/height during item size calculation.
  public var contentInsets: NSDirectionalEdgeInsets

  /// Whether to include the view's bottom safe-area inset in `contentInsets.bottom`.
  ///
  /// This is useful when `FKTabBar` is used as a `UITabBar` replacement anchored to the bottom:
  /// you typically want content to sit above the home indicator area without requiring hosts to
  /// manually add `safeAreaInsets.bottom` into `contentInsets`.
  ///
  /// - Important: This option affects layout measurement and scroll alignment, but does not
  ///   change `FKTabBar`'s own `bounds` or introduce any controller-level behavior.
  public var includesBottomSafeAreaInset: Bool
  /// Content alignment for non-fill, content-fitting layouts.
  ///
  /// Priority:
  /// 1. `widthMode == .fillEqually` => this value is ignored.
  /// 2. If content overflows available width => this value is ignored and scroll/overflow rules apply.
  /// 3. Otherwise this value controls how items are placed in remaining horizontal space.
  public var contentAlignment: FKTabBarContentAlignment
  /// Title overflow behavior.
  public var titleOverflowMode: FKTabBarTitleOverflowMode
  /// Large text strategy used when `traitCollection.preferredContentSizeCategory.isAccessibilityCategory == true`.
  public var largeTextLayoutStrategy: FKTabBarLargeTextLayoutStrategy
  /// Minimum item height.
  public var minimumItemHeight: CGFloat
  /// Preferred visual bar height (excluding content insets).
  ///
  /// When `nil`, the component falls back to `minimumItemHeight`.
  public var preferredBarHeight: CGFloat?
  /// Determines whether intrinsic height should add bottom safe area.
  public var safeAreaHeightPolicy: FKTabBarSafeAreaHeightPolicy
  /// Item width strategy.
  public var widthMode: FKTabBarItemWidthMode
  /// Optional custom width provider.
  ///
  /// Return `nil` to fall back to `widthMode`. The provider is called frequently during
  /// layout passes, so avoid expensive work inside this closure.
  public var customWidthProvider: ((_ index: Int, _ item: FKTabBarItem) -> CGFloat?)?
  /// Layout direction for each tab item's icon and title.
  ///
  /// - `.horizontal`: icon and title are laid out in one row.
  /// - `.vertical`: icon and title are laid out in one column.
  ///
  /// Spacing between icon and title is controlled by the underlying `FKButton` image/title spacing.
  /// This setting affects item measurement and rendering together.
  public var itemLayoutDirection: FKTabBarItemLayoutDirection
  /// RTL behavior override.
  public var rtlBehavior: FKTabBarRTLBehavior
  /// Position strategy used when selecting item.
  ///
  /// This also affects post-rotation realignment behavior.
  public var selectionScrollPosition: FKTabBarSelectionScrollPosition
  /// Animation config for selection auto-scroll.
  public var selectionScrollAnimation: FKTabBarSelectionScrollAnimation

  public init(
    isScrollable: Bool = true,
    itemSpacing: CGFloat = 8,
    customSpacingProvider: ((_ context: SpacingContext) -> CGFloat?)? = nil,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8),
    includesBottomSafeAreaInset: Bool = false,
    contentAlignment: FKTabBarContentAlignment = .leading,
    titleOverflowMode: FKTabBarTitleOverflowMode = .automaticWidth,
    largeTextLayoutStrategy: FKTabBarLargeTextLayoutStrategy = .automatic,
    minimumItemHeight: CGFloat = 44,
    preferredBarHeight: CGFloat? = nil,
    safeAreaHeightPolicy: FKTabBarSafeAreaHeightPolicy = .excludeBottomSafeArea,
    widthMode: FKTabBarItemWidthMode = .intrinsic,
    customWidthProvider: ((_ index: Int, _ item: FKTabBarItem) -> CGFloat?)? = nil,
    itemLayoutDirection: FKTabBarItemLayoutDirection = .horizontal,
    rtlBehavior: FKTabBarRTLBehavior = .automatic,
    selectionScrollPosition: FKTabBarSelectionScrollPosition = .center,
    selectionScrollAnimation: FKTabBarSelectionScrollAnimation = FKTabBarSelectionScrollAnimation()
  ) {
    self.isScrollable = isScrollable
    self.itemSpacing = itemSpacing
    self.customSpacingProvider = customSpacingProvider
    self.contentInsets = contentInsets
    self.includesBottomSafeAreaInset = includesBottomSafeAreaInset
    self.contentAlignment = contentAlignment
    self.titleOverflowMode = titleOverflowMode
    self.largeTextLayoutStrategy = largeTextLayoutStrategy
    self.minimumItemHeight = minimumItemHeight
    self.preferredBarHeight = preferredBarHeight
    self.safeAreaHeightPolicy = safeAreaHeightPolicy
    self.widthMode = widthMode
    self.customWidthProvider = customWidthProvider
    self.itemLayoutDirection = itemLayoutDirection
    self.rtlBehavior = rtlBehavior
    self.selectionScrollPosition = selectionScrollPosition
    self.selectionScrollAnimation = selectionScrollAnimation
  }
}

// MARK: - Appearance

/// Visual appearance tokens for `FKTabBar`.
public struct FKTabBarAppearance {
  /// Background style.
  public enum BackgroundStyle: Equatable {
    case solid(UIColor)
    case systemBlur(UIBlurEffect.Style)
  }

  /// Divider edge position.
  public enum DividerPosition: Equatable {
    case top
    case bottom
  }

  /// Shadow tokens for bar surface.
  public struct Shadow: Equatable {
    public var color: UIColor
    public var opacity: Float
    public var radius: CGFloat
    public var offset: CGSize

    public init(
      color: UIColor = .black,
      opacity: Float = 0,
      radius: CGFloat = 0,
      offset: CGSize = .zero
    ) {
      self.color = color
      self.opacity = opacity
      self.radius = radius
      self.offset = offset
    }
  }

  /// Typography tokens.
  public struct Typography: Equatable {
    /// Title font for non-selected items.
    public var normalFont: UIFont
    /// Title font for selected items.
    public var selectedFont: UIFont
    /// Whether fonts scale with Dynamic Type.
    public var adjustsForContentSizeCategory: Bool
    /// Allows wrapping title to two lines when space is tight.
    public var allowsTwoLineTitle: Bool

    public init(
      normalFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
      selectedFont: UIFont = .systemFont(ofSize: 14, weight: .semibold),
      adjustsForContentSizeCategory: Bool = true,
      allowsTwoLineTitle: Bool = false
    ) {
      self.normalFont = normalFont
      self.selectedFont = selectedFont
      self.adjustsForContentSizeCategory = adjustsForContentSizeCategory
      self.allowsTwoLineTitle = allowsTwoLineTitle
    }
  }

  /// Color tokens.
  public struct Colors: Equatable {
    /// Title color for non-selected items.
    public var normalText: UIColor
    /// Title color for selected items.
    public var selectedText: UIColor
    /// Title color for disabled items.
    public var disabledText: UIColor

    /// Icon tint for non-selected items.
    public var normalIcon: UIColor
    /// Icon tint for selected items.
    public var selectedIcon: UIColor
    /// Icon tint for disabled items.
    public var disabledIcon: UIColor
    /// Primary indicator color used by styles that require a single tint.
    public var indicator: UIColor
    /// Divider color at the bottom edge.
    public var divider: UIColor

    public init(
      normalText: UIColor = .secondaryLabel,
      selectedText: UIColor = .label,
      disabledText: UIColor = .tertiaryLabel,
      normalIcon: UIColor = .secondaryLabel,
      selectedIcon: UIColor = .label,
      disabledIcon: UIColor = .tertiaryLabel,
      indicator: UIColor = .label,
      divider: UIColor = .separator
    ) {
      self.normalText = normalText
      self.selectedText = selectedText
      self.disabledText = disabledText
      self.normalIcon = normalIcon
      self.selectedIcon = selectedIcon
      self.disabledIcon = disabledIcon
      self.indicator = indicator
      self.divider = divider
    }
  }

  /// Surface background rendering style.
  public var backgroundStyle: BackgroundStyle
  /// Typography tokens shared by all tab cells.
  public var typography: Typography
  /// Color tokens shared by all tab cells.
  public var colors: Colors
  /// Global subtitle style for all items.
  ///
  /// Item-level `FKTabBarItem.subtitle` has priority when provided.
  public var subtitleConfiguration: FKTabBarTextConfiguration
  /// Indicator rendering style.
  public var indicatorStyle: FKTabBarIndicatorStyle
  /// Whether a divider is shown.
  public var showsDivider: Bool
  /// Divider edge position.
  public var dividerPosition: DividerPosition
  /// Surface shadow styling.
  ///
  /// Use a subtle top-edge style to mimic system tab bars when docked at screen bottom.
  public var shadow: Shadow

  public init(
    backgroundStyle: BackgroundStyle = .solid(.systemBackground),
    typography: Typography = Typography(),
    colors: Colors = Colors(),
    subtitleConfiguration: FKTabBarTextConfiguration = .init(),
    indicatorStyle: FKTabBarIndicatorStyle = .line(FKTabBarLineIndicatorConfiguration()),
    showsDivider: Bool = true,
    dividerPosition: DividerPosition = .bottom,
    shadow: Shadow = Shadow()
  ) {
    self.backgroundStyle = backgroundStyle
    self.typography = typography
    self.colors = colors
    self.subtitleConfiguration = subtitleConfiguration
    self.indicatorStyle = indicatorStyle
    self.showsDivider = showsDivider
    self.dividerPosition = dividerPosition
    self.shadow = shadow
  }
}

// MARK: - Animation

/// Animation configuration for tab transitions.
public struct FKTabBarAnimationConfiguration: Equatable {
  /// Indicator animation configuration.
  public var indicatorAnimation: FKTabBarIndicatorAnimation
  /// Whether text/icon color interpolation should follow gesture progress.
  ///
  /// Disabling this can reduce per-frame work for very dense tab strips.
  public var allowsProgressiveColorTransition: Bool
  /// Whether font weight transition should interpolate during progress.
  ///
  /// Font interpolation is approximated by toggling selected font near progress midpoint to avoid expensive per-frame font synthesis.
  public var allowsProgressiveFontTransition: Bool

  public init(
    indicatorAnimation: FKTabBarIndicatorAnimation = .spring(duration: 0.28, damping: 0.88, velocity: 0.2),
    allowsProgressiveColorTransition: Bool = true,
    allowsProgressiveFontTransition: Bool = false
  ) {
    self.indicatorAnimation = indicatorAnimation
    self.allowsProgressiveColorTransition = allowsProgressiveColorTransition
    self.allowsProgressiveFontTransition = allowsProgressiveFontTransition
  }
}

/// Root configuration for `FKTabBar`.
///
/// This is the single public configuration entry point. Sub-configuration priority:
/// 1. item-level configuration (`FKTabBarItem`)
/// 2. `FKTabBarConfiguration` values
/// 3. internal defaults
public struct FKTabBarConfiguration {
  /// Layout behavior.
  public var layout: FKTabBarLayoutConfiguration
  /// Appearance tokens.
  public var appearance: FKTabBarAppearance
  /// Animation behavior.
  public var animation: FKTabBarAnimationConfiguration

  public init(
    layout: FKTabBarLayoutConfiguration = .init(),
    appearance: FKTabBarAppearance = .init(),
    animation: FKTabBarAnimationConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.animation = animation
  }
}

/// Global defaults namespace for tab component.
@MainActor
public enum FKTabBarDefaults {
  /// Default root configuration used by `FKTabBar`.
  public static var defaultConfiguration = FKTabBarConfiguration()
}

