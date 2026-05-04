import UIKit
import FKCompositeKit
import FKUIKit

/// Shared tab bar + chevron metrics for Filter examples.
enum FKFilterExampleAppearance {
  /// Total height for the embedded ``FKFilterController`` chrome row (was 56; −4pt).
  static let filterStripChromeHeight: CGFloat = 52

  /// Horizontal ``FKButton`` content insets for each tab (default in cells is 8pt; −4pt per side for demos).
  private static let filterTabButtonHorizontalInset: CGFloat = 4

  /// Applies tighter tab button insets on the dropdown’s ``FKTabBar`` (runs after each cell refresh).
  static func applyFilterExampleTabButtonContentInsets(to tabBar: FKTabBar) {
    tabBar.itemButtonConfigurator = { button, _, _ in
      let appearance = FKButtonAppearance(
        backgroundColor: .clear,
        contentInsets: .init(
          top: 6,
          leading: filterTabButtonHorizontalInset,
          bottom: 6,
          trailing: filterTabButtonHorizontalInset
        )
      )
      button.setAppearance(appearance, for: .normal)
      button.setAppearance(appearance, for: .selected)
      button.setAppearance(appearance, for: .disabled)
    }
  }

  /// Selected chip / grid label color in filter panels (`FKFilterPillStyle` default); strip expanded tab uses the same.
  private static let filterSelectionAccentColor = UIColor.systemRed

  static let panelPillStyle = FKFilterPillStyle(
    cornerRadius: 6,
    contentInsets: .init(top: 6, left: 8, bottom: 6, right: 8),
    selectedTextColor: filterSelectionAccentColor,
    selectedBackgroundColor: filterSelectionAccentColor.withAlphaComponent(0.10),
    selectedBorderColor: filterSelectionAccentColor.withAlphaComponent(0.55)
  )

  /// Right column / single-column list rows (white background).
  static let panelListCellStyle = FKFilterListCellStyle()

  /// Left sidebar in two-column panels; matches ``FKFilterTwoColumnGridViewController`` default sidebar coloring.
  static let panelSidebarListCellStyle = FKFilterListCellStyle(
    rowBackgroundColor: UIColor.systemGray6.withAlphaComponent(0.6),
    selectedRowBackgroundColor: .systemBackground
  )

  static let titleStyle: UIFont.TextStyle = .subheadline
  static let subtitleStyle: UIFont.TextStyle = .caption2
  static let chevronSize = CGSize(width: 14, height: 14)
  static let chevronSpacing: CGFloat = 4
  static let titleSubtitleSpacing: CGFloat = 2

  static var filterStripMetrics: FKFilterStripMetrics {
    FKFilterStripMetrics(
      titleTextStyle: titleStyle,
      subtitleTextStyle: subtitleStyle,
      chevronSize: chevronSize,
      chevronSpacing: chevronSpacing,
      titleSubtitleSpacing: titleSubtitleSpacing,
      expandedTitleColor: filterSelectionAccentColor,
      expandedChevronColor: filterSelectionAccentColor
    )
  }

  /// Six-tab hub: intrinsic tab widths (horizontal scroll), so long titles are not clipped.
  static func hubAnchoredConfiguration() -> FKAnchoredDropdownConfiguration {
    var cfg = FKAnchoredDropdownConfiguration.default
    cfg.tabBarConfiguration.layout.isScrollable = true
    cfg.tabBarConfiguration.layout.widthMode = .intrinsic
    cfg.tabBarConfiguration.layout.itemSpacing = 4
    cfg.tabBarConfiguration.layout.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    cfg.tabBarConfiguration.layout.contentAlignment = .leading
    cfg.applyTintOnlyChevronTabTypography(textStyle: .subheadline)
    return cfg
  }

  /// Three tabs: equal width, no horizontal scroll.
  static func equalThreeAnchoredConfiguration() -> FKAnchoredDropdownConfiguration {
    var cfg = FKAnchoredDropdownConfiguration.default
    cfg.tabBarConfiguration.layout.isScrollable = false
    cfg.tabBarConfiguration.layout.widthMode = .fillEqually
    cfg.tabBarConfiguration.layout.itemSpacing = 0
    cfg.tabBarConfiguration.layout.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
    cfg.applyTintOnlyChevronTabTypography(textStyle: .subheadline)
    return cfg
  }

}
