import UIKit
import FKCompositeKit
import FKUIKit

/// Shared tab bar + chevron metrics for Filter examples.
enum FKFilterExampleAppearance {
  static let panelPillStyle = FKFilterPillStyle(
    cornerRadius: 6,
    contentInsets: .init(top: 6, left: 8, bottom: 6, right: 8)
  )

  static let panelListCellStyle = FKFilterListCellStyle()

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
      titleSubtitleSpacing: titleSubtitleSpacing
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
