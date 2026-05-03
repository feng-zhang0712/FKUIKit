import UIKit

/// Supplies tab items dynamically, similar to `UITableViewDataSource`.
///
/// When set, `reloadData()` rebuilds from this source; `reload(items:)` still updates the manual cache used when `dataSource` is `nil`.
@MainActor
public protocol FKTabBarDataSource: AnyObject {
  /// Returns number of items available for the tab bar.
  func numberOfItems(in tabBar: FKTabBar) -> Int
  /// Returns item for a data-source index in `[0..<numberOfItems]`.
  func tabBar(_ tabBar: FKTabBar, itemAt index: Int) -> FKTabBarItem
}
