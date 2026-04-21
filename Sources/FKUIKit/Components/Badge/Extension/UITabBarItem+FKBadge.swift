import UIKit

public extension UITabBarItem {
  /// Returns overlay badge controller when the tab bar item host view is available.
  ///
  /// This enables custom dot/text/count rendering beyond UIKit `badgeValue`.
  @MainActor
  var fk_badge: FKBadgeController? {
    fk_badgeHostView?.fk_badge
  }

  /// Applies the same overflow rules as `FKBadgeFormatter` to the system `badgeValue` string.
  ///
  /// - Parameters:
  ///   - count: Optional count. `nil` or `<= 0` clears `badgeValue`.
  ///   - maxDisplay: Maximum value displayed before overflow suffix is appended.
  ///   - overflowSuffix: Suffix used for overflow display (for example `"+"`).
  func fk_setBadgeCount(_ count: Int?, maxDisplay: Int = 99, overflowSuffix: String = "+") {
    guard let count, count > 0 else {
      badgeValue = nil
      return
    }
    let configuration = FKBadgeConfiguration(maxDisplayCount: maxDisplay, overflowSuffix: overflowSuffix)
    badgeValue = FKBadgeFormatter.displayString(count: count, configuration: configuration)
  }

  /// One-line helper to show custom numeric badge as overlay.
  ///
  /// - Parameters:
  ///   - count: Numeric value to display.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showCount(count, animated: animated, animation: animation)
  }

  /// One-line helper to show custom text badge as overlay.
  ///
  /// - Parameters:
  ///   - text: Badge text value.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showText(text, animated: animated, animation: animation)
  }

  /// One-line helper to show pure red dot as overlay.
  ///
  /// - Parameters:
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showDot(animated: animated, animation: animation)
  }

  /// One-line helper to clear both overlay and system badge text.
  ///
  /// - Parameter animated: Whether hide transition should animate.
  @MainActor
  func fk_hideBadge(animated: Bool = false) {
    fk_badge?.clear(animated: animated)
    badgeValue = nil
  }
}

private extension UITabBarItem {
  // UIKit host view lookup used by overlay badge mode.
  var fk_badgeHostView: UIView? {
    value(forKey: "view") as? UIView
  }
}
