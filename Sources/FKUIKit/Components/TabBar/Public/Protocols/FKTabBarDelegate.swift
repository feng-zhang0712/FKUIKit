import UIKit

/// Optional delegate for selection gating and tab lifecycle callbacks.
///
/// Prefer this when integrating with UIKit view controllers; closures on `FKTabBar` cover the same events for lightweight setups.
@MainActor
public protocol FKTabBarDelegate: AnyObject {
  /// Asks whether selection can proceed.
  ///
  /// Return `false` to block selection before visual state and callbacks are emitted.
  ///
  /// - Parameters:
  ///   - tabBar: The sender tab bar.
  ///   - item: The candidate item.
  ///   - index: The candidate visible index.
  ///   - reason: The semantic source of the selection request.
  /// - Returns: `true` to allow selection commit; `false` to reject.
  func tabBar(_ tabBar: FKTabBar, shouldSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) -> Bool
  /// Called after selection gating passes and before visual commit.
  func tabBar(_ tabBar: FKTabBar, willSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason)
  /// Called after selection is committed and rendered.
  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason)
  /// Called when user taps the already selected tab and reducer resolves to reselect.
  func tabBar(_ tabBar: FKTabBar, didReselect item: FKTabBarItem, at index: Int)

  /// Called when user long-presses a tab item.
  ///
  /// - Important: This callback is UI-only and does not imply selection.
  func tabBar(_ tabBar: FKTabBar, didLongPress item: FKTabBarItem, at index: Int)

  /// Called in controlled mode when a user tap requests selection.
  ///
  /// This callback does not imply selection has been committed.
  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int)

  /// Called after tabs are reloaded and effective visible items are finalized.
  func tabBar(_ tabBar: FKTabBar, didReloadItems items: [FKTabBarItem], visibleItems: [FKTabBarItem], selectedIndex: Int)
}

public extension FKTabBarDelegate {
  func tabBar(_ tabBar: FKTabBar, shouldSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) -> Bool { true }
  func tabBar(_ tabBar: FKTabBar, willSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {}
  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {}
  func tabBar(_ tabBar: FKTabBar, didReselect item: FKTabBarItem, at index: Int) {}
  func tabBar(_ tabBar: FKTabBar, didLongPress item: FKTabBarItem, at index: Int) {}
  func tabBar(_ tabBar: FKTabBar, didRequestSelection item: FKTabBarItem, at index: Int) {}
  func tabBar(_ tabBar: FKTabBar, didReloadItems items: [FKTabBarItem], visibleItems: [FKTabBarItem], selectedIndex: Int) {}
}
