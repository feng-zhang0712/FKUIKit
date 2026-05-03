import UIKit

public extension UITabBarItem {
  /// Overlay badge when the tab bar item's host view exists.
  @MainActor var fk_badge: FKBadgeController? {
    fk_badgeHostView?.fk_badge
  }

  /// Applies the same overflow rules as `FKBadgeFormatter` to UIKit `badgeValue`.
  func fk_setBadgeCount(_ count: Int?, maxDisplay: Int = 99, overflowSuffix: String = "+") {
    guard let count, count > 0 else {
      badgeValue = nil
      return
    }
    let configuration = FKBadgeConfiguration(maxDisplayCount: maxDisplay, overflowSuffix: overflowSuffix)
    badgeValue = FKBadgeFormatter.displayString(count: count, configuration: configuration)
  }

  @MainActor func fk_showBadgeCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showCount(count, animated: animated, animation: animation)
  }

  @MainActor func fk_showBadgeText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showText(text, animated: animated, animation: animation)
  }

  @MainActor func fk_showBadgeDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showDot(animated: animated, animation: animation)
  }

  /// Clears the custom overlay and clears `badgeValue`.
  @MainActor func fk_clearBadge(animated: Bool = false) {
    fk_badge?.clear(animated: animated)
    badgeValue = nil
  }
}

private extension UITabBarItem {
  var fk_badgeHostView: UIView? {
    value(forKey: "view") as? UIView
  }
}
