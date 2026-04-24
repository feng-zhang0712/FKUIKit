import UIKit
import FKUIKit

public extension FKFilterBarPresentation {
  /// Visual appearance for bar items (the clickable tabs).
  ///
  /// This is intentionally small and focused:
  /// - Colors/fonts/alignment for title + subtitle
  /// - Spacing between title/subtitle and chevron
  ///
  /// Panel appearance (mask/corner radius/host, etc.) is configured via `Configuration.presentationConfiguration`.
  struct BarItemAppearance {
    public var normalTitleColor: UIColor
    public var selectedTitleColor: UIColor
    public var normalSubtitleColor: UIColor
    public var selectedSubtitleColor: UIColor
    public var normalChevronColor: UIColor
    public var selectedChevronColor: UIColor
    public var titleFont: UIFont
    public var subtitleFont: UIFont
    public var titleAlignment: NSTextAlignment
    public var subtitleAlignment: NSTextAlignment
    public var titleSubtitleSpacing: CGFloat
    public var chevronPointSize: CGFloat
    public var chevronSpacing: CGFloat

    public init(
      normalTitleColor: UIColor = .label,
      selectedTitleColor: UIColor = .systemRed,
      normalSubtitleColor: UIColor = .secondaryLabel,
      selectedSubtitleColor: UIColor = .systemRed,
      normalChevronColor: UIColor = .secondaryLabel,
      selectedChevronColor: UIColor = .systemRed,
      titleFont: UIFont = .preferredFont(forTextStyle: .subheadline),
      subtitleFont: UIFont = .preferredFont(forTextStyle: .caption2),
      titleAlignment: NSTextAlignment = .center,
      subtitleAlignment: NSTextAlignment = .center,
      titleSubtitleSpacing: CGFloat = 2,
      chevronPointSize: CGFloat = 11,
      chevronSpacing: CGFloat = 4
    ) {
      self.normalTitleColor = normalTitleColor
      self.selectedTitleColor = selectedTitleColor
      self.normalSubtitleColor = normalSubtitleColor
      self.selectedSubtitleColor = selectedSubtitleColor
      self.normalChevronColor = normalChevronColor
      self.selectedChevronColor = selectedChevronColor
      self.titleFont = titleFont
      self.subtitleFont = subtitleFont
      self.titleAlignment = titleAlignment
      self.subtitleAlignment = subtitleAlignment
      self.titleSubtitleSpacing = max(0, titleSubtitleSpacing)
      self.chevronPointSize = chevronPointSize
      self.chevronSpacing = chevronSpacing
    }
  }

  /// High-level configuration for `FKFilterBarPresentation`.
  ///
  /// - `barItemAppearance`: Controls the tab button look.
  /// - `tabBarAppearance`: Passed through to `FKTabBar` (colors/indicator/typography).
  /// - `tabBarLayout`: Passed through to `FKTabBar` (layout/alignment/spacing).
  /// - `presentationConfiguration`: Passed through to `FKPresentation` (mask/layout/corners).
  ///
  /// Tip: Prefer starting from `.default` and tweaking a few fields.
  struct Configuration {
    public var barItemAppearance: BarItemAppearance
    public var tabBarAppearance: FKTabBarAppearance
    public var tabBarLayout: FKTabBarLayoutConfiguration
    public var presentationConfiguration: FKPresentation.Configuration

    public static var `default`: Configuration {
      var tabAppearance = FKTabBarAppearance()
      tabAppearance.backgroundStyle = .solid(.systemBackground)
      tabAppearance.showsDivider = false
      // Indicator is not needed for filter bar (chevron conveys expanded state).
      tabAppearance.indicatorStyle = .none

      var tabLayout = FKTabBarLayoutConfiguration()
      tabLayout.widthMode = .intrinsic
      tabLayout.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
      tabLayout.itemSpacing = 0
      tabLayout.contentAlignment = .spaceAround

      var pres = FKPresentation.Configuration.default
      pres.layout.widthMode = .fullWidth
      pres.layout.horizontalAlignment = .center
      pres.layout.verticalSpacing = 0
      pres.layout.preferBelowSource = true
      pres.layout.allowFlipToAbove = false
      pres.layout.clampToSafeArea = false
      pres.mask.enabled = true
      pres.mask.tapToDismissEnabled = true
      pres.mask.alpha = 0.25
      pres.appearance.backgroundColor = .systemBackground
      pres.appearance.alpha = 1
      pres.appearance.cornerRadius = 10
      pres.appearance.cornerCurve = .continuous
      pres.appearance.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
      pres.appearance.shadow = nil
      pres.content.containerInsets = .zero
      pres.content.fallbackBackgroundColor = .systemBackground

      return Configuration(
        barItemAppearance: .init(),
        tabBarAppearance: tabAppearance,
        tabBarLayout: tabLayout,
        presentationConfiguration: pres
      )
    }

    public init(
      barItemAppearance: BarItemAppearance = .init(),
      tabBarAppearance: FKTabBarAppearance = Configuration.default.tabBarAppearance,
      tabBarLayout: FKTabBarLayoutConfiguration = Configuration.default.tabBarLayout,
      presentationConfiguration: FKPresentation.Configuration = Configuration.default.presentationConfiguration
    ) {
      self.barItemAppearance = barItemAppearance
      self.tabBarAppearance = tabBarAppearance
      self.tabBarLayout = tabBarLayout
      self.presentationConfiguration = presentationConfiguration
    }
  }
}

