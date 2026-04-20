//
// FKBadgeUIViewSwizzling.swift
//

import UIKit
import ObjectiveC

/// Installs a one-time `didMoveToSuperview` hook so badges re-attach when the target view moves in the hierarchy.
enum FKBadgeUIViewSwizzling {
  /// One-time swizzle flag; only ever toggled on the main thread from `installIfNeeded()`.
  nonisolated(unsafe) private static var didInstall = false

  /// Re-anchors badges when any view moves in the hierarchy (add/remove superview, etc.).
  static func installIfNeeded() {
    guard !didInstall else { return }
    didInstall = true

    let a = #selector(UIView.didMoveToSuperview)
    let b = #selector(UIView.fk_badge_replacement_didMoveToSuperview)

    guard
      let methodA = class_getInstanceMethod(UIView.self, a),
      let methodB = class_getInstanceMethod(UIView.self, b)
    else { return }

    method_exchangeImplementations(methodA, methodB)
  }
}

extension UIView {
  /// Swapped with `didMoveToSuperview`; forwards to the original implementation, then notifies badge attachments.
  @objc func fk_badge_replacement_didMoveToSuperview() {
    fk_badge_replacement_didMoveToSuperview()
    FKBadgeController.handleTargetViewMoved(self)
  }
}
