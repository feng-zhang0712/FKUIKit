//
// UIBarButtonItem+FKBadge.swift
//

import UIKit

public extension UIBarButtonItem {
  /// Returns the badge controller for `customView` when present. System bar-button chrome cannot host this overlay.
  var fk_badge: FKBadgeController? {
    customView.map { $0.fk_badge }
  }
}
