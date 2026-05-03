import UIKit
import FKUIKit

/// A tab descriptor for `FKAnchoredDropdownController`.
public struct FKAnchoredDropdownTab<TabID: Hashable> {
  /// Snapshot used when building tab UI and content.
  public struct StateSnapshot: Equatable {
    /// Currently expanded tab (if any).
    public var expandedTab: TabID?
    /// Most recently selected tab (if any).
    public var selectedTab: TabID?

    public init(expandedTab: TabID?, selectedTab: TabID?) {
      self.expandedTab = expandedTab
      self.selectedTab = selectedTab
    }
  }

  /// Content descriptor.
  public enum Content {
    /// Provide a view controller directly.
    case viewController(() -> UIViewController)
    /// Provide a view and wrap it in a lightweight hosting controller.
    case view(() -> UIView)
  }

  /// Unique identifier for this tab.
  public let id: TabID
  /// Builds the `FKTabBarItem` used by `FKTabBar`.
  ///
  /// - Important: You are expected to reflect `snapshot.expandedTab` in the resulting item's
  ///   selected/normal styles (for example, arrow direction or emphasis), so the tab visuals can
  ///   reset back to "collapsed" after dismissal even if `FKTabBar` still keeps a selected index.
  public var makeTabBarItem: (_ snapshot: StateSnapshot) -> FKTabBarItem
  /// Provides the dropdown content for this tab.
  public var content: Content

  public init(
    id: TabID,
    makeTabBarItem: @escaping (_ snapshot: StateSnapshot) -> FKTabBarItem,
    content: Content
  ) {
    self.id = id
    self.makeTabBarItem = makeTabBarItem
    self.content = content
  }
}

public extension FKAnchoredDropdownTab {
  /// A lightweight default tab builder using a title + chevron that flips up/down based on expanded state.
  ///
  /// This is a convenience for teams that don't need fully custom item views.
  static func chevronTitle(
    id: TabID,
    itemID: String? = nil,
    title: @escaping () -> String,
    subtitle: (() -> String?)? = nil,
    normalTitleColor: UIColor = .label,
    expandedTitleColor: UIColor = .systemRed,
    normalChevronColor: UIColor = .secondaryLabel,
    expandedChevronColor: UIColor = .systemRed,
    titleFont: UIFont = .preferredFont(forTextStyle: .subheadline),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .caption2),
    chevronSize: CGSize = .init(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2,
    content: Content
  ) -> Self {
    FKAnchoredDropdownTab(
      id: id,
      makeTabBarItem: { snapshot in
        let isExpanded = snapshot.expandedTab == id
        let titleText = title()
        let subtitleText = subtitle?()

        var titleConfig = FKTabBarTextConfiguration(
          normal: .init(
            text: titleText,
            style: FKTabBarTextStyle(font: titleFont, color: isExpanded ? expandedTitleColor : normalTitleColor)
          ),
          selected: .init(
            text: titleText,
            style: FKTabBarTextStyle(font: titleFont, color: isExpanded ? expandedTitleColor : normalTitleColor)
          )
        )
        titleConfig.spacingToNextText = max(0, titleSubtitleSpacing)

        let subtitleConfig: FKTabBarTextConfiguration? = subtitleText.map { value in
          FKTabBarTextConfiguration(
            normal: .init(
              text: value,
              style: FKTabBarTextStyle(font: subtitleFont, color: isExpanded ? expandedTitleColor : normalTitleColor)
            ),
            selected: .init(
              text: value,
              style: FKTabBarTextStyle(font: subtitleFont, color: isExpanded ? expandedTitleColor : normalTitleColor)
            )
          )
        }

        let image = FKTabBarImageConfiguration(
          normal: .init(
            source: .systemSymbol(name: isExpanded ? "chevron.up" : "chevron.down"),
            style: FKTabBarImageStyle(
              tintColor: isExpanded ? expandedChevronColor : normalChevronColor,
              fixedSize: chevronSize,
              spacingToTitle: max(0, chevronSpacing),
              position: .trailing
            )
          ),
          selected: .init(
            source: .systemSymbol(name: isExpanded ? "chevron.up" : "chevron.down"),
            style: FKTabBarImageStyle(
              tintColor: isExpanded ? expandedChevronColor : normalChevronColor,
              fixedSize: chevronSize,
              spacingToTitle: max(0, chevronSpacing),
              position: .trailing
            )
          )
        )

        return FKTabBarItem(
          id: itemID ?? String(describing: id),
          title: titleConfig,
          subtitle: subtitleConfig,
          image: image,
          isEnabled: true,
          isHidden: false
        )
      },
      content: content
    )
  }
}
