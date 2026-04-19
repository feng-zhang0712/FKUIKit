//
// UITabBarItem+FKBadge.swift
//

import UIKit

public extension UITabBarItem {
  /// Applies the same overflow rules as `FKBadgeFormatter` to the system `badgeValue` string.
  func fk_setBadgeCount(_ count: Int?, maxDisplay: Int = 99, overflowSuffix: String = "+") {
    guard let count, count > 0 else {
      badgeValue = nil
      return
    }
    let configuration = FKBadgeConfiguration(maxDisplayCount: maxDisplay, overflowSuffix: overflowSuffix)
    badgeValue = FKBadgeFormatter.displayString(count: count, configuration: configuration)
  }
}
