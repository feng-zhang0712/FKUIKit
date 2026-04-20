//
// UIView+FKBadge.swift
//

import ObjectiveC
import UIKit

public extension UIView {
  /// Lazily creates a single `FKBadgeController` per view. Must be used from the main actor (typical for UIKit).
  @MainActor var fk_badge: FKBadgeController {
    fk_badgeControllerGetOrCreate()
  }
}

@MainActor
private extension UIView {
  func fk_badgeControllerGetOrCreate() -> FKBadgeController {
    if let existing = objc_getAssociatedObject(self, &FKBadgeAssociatedKeys.controller) as? FKBadgeController {
      return existing
    }
    let created = FKBadgeController(target: self)
    objc_setAssociatedObject(self, &FKBadgeAssociatedKeys.controller, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return created
  }
}
