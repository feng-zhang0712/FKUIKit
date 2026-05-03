//
// FKCornerShadowLayoutObserver.swift
//

import ObjectiveC.runtime
import UIKit

/// One-time `UIView.layoutSubviews` swizzle so bounded views refresh their cached paths.
@MainActor
enum FKCornerShadowLayoutObserver {
  private static var isInstalled = false

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
  @objc func fk_cornerShadow_layoutSubviews() {
    fk_cornerShadow_layoutSubviews()
    FKCornerShadowRenderer.refreshIfNeeded(for: self)
  }
}
