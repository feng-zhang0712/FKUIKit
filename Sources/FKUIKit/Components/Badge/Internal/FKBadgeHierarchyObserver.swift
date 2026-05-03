import ObjectiveC
import UIKit

/// Installs a one-time `UIView.didMoveToSuperview` hook so badges re-attach when the target view moves in the hierarchy.
enum FKBadgeHierarchyObserver {
  nonisolated(unsafe) private static var didInstall = false

  /// Safe to call repeatedly; installation is guarded by `didInstall`.
  static func installIfNeeded() {
    guard !didInstall else { return }
    didInstall = true

    let original = #selector(UIView.didMoveToSuperview)
    let swizzled = #selector(UIView.fkbadge_didMoveToSuperview)

    guard
      let methodA = class_getInstanceMethod(UIView.self, original),
      let methodB = class_getInstanceMethod(UIView.self, swizzled)
    else { return }

    method_exchangeImplementations(methodA, methodB)
  }
}

extension UIView {
  @objc func fkbadge_didMoveToSuperview() {
    fkbadge_didMoveToSuperview()
    FKBadgeController.handleTargetViewMoved(self)
  }
}
