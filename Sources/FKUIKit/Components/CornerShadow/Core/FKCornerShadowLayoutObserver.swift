//
// FKCornerShadowLayoutObserver.swift
//
// Auto layout observer for FKCornerShadow.
//

import UIKit
import ObjectiveC.runtime

/// Hooks into `UIView.layoutSubviews()` once to refresh applied styles.
///
/// This observer ensures paths stay correct after Auto Layout or rotation-driven bounds
/// changes without requiring manual refresh calls in view controllers.
@MainActor
enum FKCornerShadowLayoutObserver {
  /// Tracks whether method swizzling has already been installed.
  private static var isInstalled = false

  /// Ensures layout swizzling is installed only once.
  static func installIfNeeded() {
    fk_cornerShadowAssertMainThread()
    guard !isInstalled else { return }
    isInstalled = true

    let cls: AnyClass = UIView.self
    let originalSelector = #selector(UIView.layoutSubviews)
    let swizzledSelector = #selector(UIView.fk_cornerShadow_layoutSubviews)

    guard
      let originalMethod = class_getInstanceMethod(cls, originalSelector),
      let swizzledMethod = class_getInstanceMethod(cls, swizzledSelector)
    else {
      return
    }

    method_exchangeImplementations(originalMethod, swizzledMethod)
  }
}

extension UIView {
  /// Swizzled implementation that keeps corner/shadow paths in sync with bounds changes.
  ///
  /// - Note: This method replaces `layoutSubviews` implementation at runtime.
  @objc func fk_cornerShadow_layoutSubviews() {
    // Calls original `layoutSubviews` after swizzling.
    fk_cornerShadow_layoutSubviews()
    FKCornerShadowRenderer.refreshIfNeeded(for: self)
  }
}
