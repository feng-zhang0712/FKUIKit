//
// FKSwipeActionCellHost.swift
//
// Cell host helpers shared by table and collection cell extensions.
//

import ObjectiveC.runtime
import UIKit

@MainActor
private enum FKSwipeActionAssociatedKeys {
  /// Associated-object key storing per-cell controller.
  static var controller: UInt8 = 0
}

@MainActor
/// Abstraction for view hosts that can lazily provide a swipe controller.
protocol FKSwipeActionCellHost: AnyObject {
  /// Lazily created controller bound to this host cell.
  var fk_swipeActionController: FKSwipeActionController { get }
}

@MainActor
extension FKSwipeActionCellHost where Self: UIView {
  /// Returns existing controller or creates and stores a new one.
  var fk_swipeActionController: FKSwipeActionController {
    if let stored = objc_getAssociatedObject(self, &FKSwipeActionAssociatedKeys.controller) as? FKSwipeActionController {
      return stored
    }
    // Store controller by associated object to keep host cell API non-invasive.
    let controller = FKSwipeActionController(cellView: self, scrollView: fk_enclosingScrollView)
    objc_setAssociatedObject(self, &FKSwipeActionAssociatedKeys.controller, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return controller
  }

  /// Finds the nearest enclosing scroll container in the superview chain.
  var fk_enclosingScrollView: UIScrollView? {
    var candidate: UIView? = self.superview
    while let current = candidate {
      if let scrollView = current as? UIScrollView {
        return scrollView
      }
      candidate = current.superview
    }
    return nil
  }
}
