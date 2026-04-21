//
// UIScrollView+FKSwipeAction.swift
//
// Scroll view level control for FKSwipeAction.
//

import ObjectiveC.runtime
import UIKit

@MainActor
private enum FKSwipeActionScrollKeys {
  /// Associated-object key storing auto-close observer.
  static var closeObserver: UInt8 = 0
}

@MainActor
/// Gesture observer that closes swipe states when list scrolling begins.
private final class FKSwipeActionScrollObserver: NSObject {
  /// Observed list container.
  weak var scrollView: UIScrollView?

  /// Creates an observer and hooks into list pan gesture events.
  ///
  /// - Parameter scrollView: Scroll view that triggers auto-close behavior.
  init(scrollView: UIScrollView) {
    self.scrollView = scrollView
    super.init()
    scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
  }

  /// Handles list pan lifecycle and triggers global close on begin.
  ///
  /// - Parameter gesture: Pan gesture from host scroll view.
  @objc private func handleScrollPan(_ gesture: UIPanGestureRecognizer) {
    guard gesture.state == .began else { return }
    FKSwipeAction.closeAll(animated: true)
  }
}

public extension UIScrollView {
  /// Enables auto close behavior when the list begins scrolling.
  ///
  /// This method is idempotent and only installs one observer per scroll view.
  func fk_enableSwipeActionAutoCloseOnScroll() {
    if objc_getAssociatedObject(self, &FKSwipeActionScrollKeys.closeObserver) != nil {
      return
    }
    let observer = FKSwipeActionScrollObserver(scrollView: self)
    objc_setAssociatedObject(self, &FKSwipeActionScrollKeys.closeObserver, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  /// Closes all visible opened swipe actions inside this list.
  ///
  /// `FKSwipeAction` keeps global state, so this closes all currently opened cells.
  ///
  /// - Parameter animated: Whether close transition should be animated.
  func fk_closeAllSwipeActions(animated: Bool = true) {
    FKSwipeAction.closeAll(animated: animated)
  }

  /// Enables or disables swipe action on all currently visible cells.
  ///
  /// - Parameter enabled: Interaction switch applied to visible cells only.
  func fk_setSwipeActionEnabledForVisibleCells(_ enabled: Bool) {
    if let tableView = self as? UITableView {
      tableView.visibleCells.forEach { $0.fk_setSwipeActionEnabled(enabled) }
    } else if let collectionView = self as? UICollectionView {
      collectionView.visibleCells.forEach { cell in
        (cell as UICollectionViewCell).fk_setSwipeActionEnabled(enabled)
      }
    }
  }
}
