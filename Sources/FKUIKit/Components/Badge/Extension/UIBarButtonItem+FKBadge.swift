import UIKit

public extension UIBarButtonItem {
  /// Overlay badge controller on the resolved host view (`customView`, or UIKit's internal `view` for system items).
  @MainActor var fk_badge: FKBadgeController? {
    fk_badgeHostView?.fk_badge
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

  @MainActor func fk_clearBadge(animated: Bool = false) {
    fk_badge?.clear(animated: animated)
  }
}

private extension UIBarButtonItem {
  var fk_badgeHostView: UIView? {
    if let customView { return customView }
    return value(forKey: "view") as? UIView
  }
}
