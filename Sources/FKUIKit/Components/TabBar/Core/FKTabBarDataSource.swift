import UIKit

@MainActor
public protocol FKTabBarDataSource: AnyObject {
  /// Returns number of items available for the tab bar.
  func numberOfItems(in tabBar: FKTabBar) -> Int
  /// Returns item for a data-source index in `[0..<numberOfItems]`.
  func tabBar(_ tabBar: FKTabBar, itemAt index: Int) -> FKTabBarItem
}
