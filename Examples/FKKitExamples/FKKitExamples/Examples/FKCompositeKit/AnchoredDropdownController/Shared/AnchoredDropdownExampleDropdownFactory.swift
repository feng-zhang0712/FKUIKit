import UIKit
import FKCompositeKit
import FKUIKit

/// Builds the sample ``FKAnchoredDropdownController`` and wires ``FKAnchoredDropdownConfiguration/Events`` to the demo log.
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
    config.applyTintOnlyChevronTabTypography()

    config.presentationConfiguration.contentInsets = .init(top: 8, leading: 12, bottom: 12, trailing: 12)
    config.presentationConfiguration.cornerRadius = 12

    let events = FKAnchoredDropdownConfiguration.Events<AnchoredDropdownExampleTabID>(
      onStateChange: { state in onLog("state: \(state)") },
      onExpandedTabChange: { expanded in onLog("expandedTab: \(expanded?.rawValue ?? "nil")") },
      onWillExpand: { tab in onLog("onWillExpand: \(tab.rawValue)") },
      onDidExpand: { tab in onLog("onDidExpand: \(tab.rawValue)") },
      onWillCollapse: { tab, reason in onLog("onWillCollapse: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      onDidCollapse: { tab, reason in onLog("onDidCollapse: \(tab?.rawValue ?? "nil") reason=\(reason)") },
      onWillSwitchTab: { from, to in onLog("onWillSwitchTab: \(from.rawValue) → \(to.rawValue)") },
      onDidSwitchTab: { from, to in onLog("onDidSwitchTab: \(from.rawValue) → \(to.rawValue)") }
    )

    let vc = FKAnchoredDropdownController<AnchoredDropdownExampleTabID>(
      tabs: tabs,
      tabBarHost: tabBarHost,
      configuration: config,
      events: events
    )

    vc.selectTab(.filters, animated: false)
    return vc
  }
}
