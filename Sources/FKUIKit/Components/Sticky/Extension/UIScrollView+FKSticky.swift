//
// UIScrollView+FKSticky.swift
//

import ObjectiveC
import UIKit

@MainActor
private enum FKStickyAssociationKey {
  static var engine: UInt8 = 0
}

public extension UIScrollView {
  /// Sticky engine bound to this scroll view.
  @MainActor
  var fk_stickyEngine: FKStickyEngine {
    if let cached = objc_getAssociatedObject(self, &FKStickyAssociationKey.engine) as? FKStickyEngine {
      return cached
    }
    let engine = FKStickyEngine(
      scrollView: self,
      configuration: FKStickyManager.shared.templateConfiguration
    )
    objc_setAssociatedObject(
      self,
      &FKStickyAssociationKey.engine,
      engine,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    return engine
  }

  /// Handles scroll event and updates sticky layout.
  @MainActor
  func fk_handleStickyScroll() {
    fk_stickyEngine.handleScroll()
  }

  /// Recomputes sticky layout manually.
  @MainActor
  func fk_reloadStickyLayout() {
    fk_stickyEngine.reloadLayout()
  }

  /// Clears sticky state and transforms.
  @MainActor
  func fk_resetSticky() {
    fk_stickyEngine.resetStickyState()
  }
}
