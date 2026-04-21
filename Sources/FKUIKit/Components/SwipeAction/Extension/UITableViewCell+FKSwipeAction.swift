//
// UITableViewCell+FKSwipeAction.swift
//
// Convenience APIs for attaching swipe actions to table cells.
//

import UIKit

extension UITableViewCell: FKSwipeActionCellHost {}

public extension UITableViewCell {
  /// Configures swipe actions for this cell.
  ///
  /// Call this in `tableView(_:cellForRowAt:)` to ensure reuse-safe updates.
  ///
  /// - Parameter configuration: Per-cell swipe configuration.
  func fk_configureSwipeAction(_ configuration: FKSwipeActionConfiguration = FKSwipeAction.defaultConfiguration) {
    fk_swipeActionController.configure(configuration)
    if configuration.behavior.closesOnScroll, let tableView = fk_enclosingScrollView as? UITableView {
      // Install auto-close observer once per table view when enabled.
      tableView.fk_enableSwipeActionAutoCloseOnScroll()
    }
  }

  /// One-line configuration API for common use.
  ///
  /// - Parameters:
  ///   - left: Actions shown when swiping to the right.
  ///   - right: Actions shown when swiping to the left.
  ///   - update: Optional closure for further per-cell configuration mutation.
  func fk_configureSwipeActions(
    left: [FKSwipeActionItem] = [],
    right: [FKSwipeActionItem] = [],
    update: ((inout FKSwipeActionConfiguration) -> Void)? = nil
  ) {
    var configuration = FKSwipeAction.defaultConfiguration
    configuration.leftActions = left
    configuration.rightActions = right
    update?(&configuration)
    fk_configureSwipeAction(configuration)
  }

  /// Enables or disables swipe action for this cell only.
  ///
  /// - Parameter enabled: Interaction switch for this specific cell.
  func fk_setSwipeActionEnabled(_ enabled: Bool) {
    fk_swipeActionController.setEnabled(enabled)
  }

  /// Opens one side manually.
  ///
  /// - Parameters:
  ///   - side: Side to reveal.
  ///   - animated: Whether transition should be animated.
  func fk_openSwipeAction(side: FKSwipeActionSide, animated: Bool = true) {
    fk_swipeActionController.open(side: side, animated: animated)
  }

  /// Closes the opened swipe state.
  ///
  /// - Parameter animated: Whether close transition should be animated.
  func fk_closeSwipeAction(animated: Bool = true) {
    fk_swipeActionController.close(animated: animated)
  }
}
