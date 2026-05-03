import UIKit
import FKCompositeKit
import FKUIKit

/// Builds the sample `FKAnchoredDropdownController` and wires callbacks to the demo log sink.
enum AnchoredDropdownExampleDropdownFactory {
  static func makeController(
    tabBarHost: FKAnchoredDropdownTabBarHost,
    onLog: @escaping (String) -> Void
  ) -> FKAnchoredDropdownController<AnchoredDropdownExampleTabID> {
    let tabs: [FKAnchoredDropdownTab<AnchoredDropdownExampleTabID>] = [
      .chevronTitle(
        id: .sort,
        itemID: "sort",
        title: { "Sort" },
        content: .viewController { AnchoredDropdownExampleSortPanelViewController() }
      ),
      .chevronTitle(
        id: .filters,
        itemID: "filters",
        title: { "Filters" },
        subtitle: { "3 selected" },
        content: .viewController { AnchoredDropdownExampleFiltersPanelViewController() }
      ),
      .chevronTitle(
        id: .search,
        itemID: "search",
        title: { "Search" },
        content: .viewController { AnchoredDropdownExampleSearchPanelViewController() }
      ),
    ]

    var config = FKAnchoredDropdownConfiguration.default

    // Selection is shown by text/icon tint only (same font weight as unselected).
    let titleFont = UIFont.preferredFont(forTextStyle: .subheadline)
    config.tabBarConfiguration.appearance.typography.normalFont = titleFont
    config.tabBarConfiguration.appearance.typography.selectedFont = titleFont
    config.tabBarConfiguration.appearance.typography.adjustsForContentSizeCategory = true
    config.tabBarConfiguration.appearance.colors.normalText = .secondaryLabel
    config.tabBarConfiguration.appearance.colors.selectedText = .label
    config.tabBarConfiguration.appearance.colors.normalIcon = .secondaryLabel
    config.tabBarConfiguration.appearance.colors.selectedIcon = .label

    config.presentationConfiguration.contentInsets = .init(top: 8, leading: 12, bottom: 12, trailing: 12)
    config.presentationConfiguration.cornerRadius = 12
    config.presentationConfiguration.backdropStyle = .dim(alpha: 0.25)
    config.switchAnimationStyle = .replaceInPlace(animation: .crossfade(duration: 0.18))

    let callbacks = FKAnchoredDropdownConfiguration.Callbacks<AnchoredDropdownExampleTabID>(
      stateDidChange: { state in onLog("state: \(state)") },
      expandedTabDidChange: { expanded in onLog("expandedTab: \(expanded?.rawValue ?? "nil")") },
      willOpen: { tab in onLog("willOpen: \(tab.rawValue)") },
      didOpen: { tab in onLog("didOpen: \(tab.rawValue)") },
      willClose: { tab, reason in onLog("willClose: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      didClose: { tab, reason in onLog("didClose: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      willSwitch: { from, to in onLog("willSwitch: \(from.rawValue) → \(to.rawValue)") },
      didSwitch: { from, to in onLog("didSwitch: \(from.rawValue) → \(to.rawValue)") }
    )

    let vc = FKAnchoredDropdownController<AnchoredDropdownExampleTabID>(
      tabs: tabs,
      tabBarHost: tabBarHost,
      configuration: config,
      callbacks: callbacks
    )

    // Demonstrate external "state restore" style API: preselect but do not open.
    vc.select(tab: .filters, animated: false)
    return vc
  }
}
