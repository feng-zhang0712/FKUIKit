import UIKit

public extension UIBarButtonItem {
  /// Returns the badge controller bound to the bar-button host view.
  ///
  /// For custom bar button items this uses `customView`; for system items it resolves the internal
  /// UIKit host view via KVC, allowing the same badge API on both sides.
  @MainActor
  var fk_badge: FKBadgeController? {
    fk_badgeHostView?.fk_badge
  }

  /// One-line helper to show a numeric badge on the host view.
  ///
  /// - Parameters:
  ///   - count: Numeric value to display.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showCount(count, animated: animated, animation: animation)
  }

  /// One-line helper to show text badge on the host view.
  ///
  /// - Parameters:
  ///   - text: Badge text value.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showText(text, animated: animated, animation: animation)
  }

  /// One-line helper to show pure dot on the host view.
  ///
  /// - Parameters:
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  @MainActor
  func fk_showBadgeDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge?.showDot(animated: animated, animation: animation)
  }

  /// One-line helper to clear badge.
  ///
  /// - Parameter animated: Whether hide transition should animate.
  @MainActor
  func fk_hideBadge(animated: Bool = false) {
    fk_badge?.clear(animated: animated)
  }
}

private extension UIBarButtonItem {
  // Resolves the underlying `UIView` used for overlay badge attachment.
  // Falls back to KVC for system items that do not expose `customView`.
  var fk_badgeHostView: UIView? {
    if let customView { return customView }
    return value(forKey: "view") as? UIView
  }
}
