import ObjectiveC
import UIKit

public extension UIView {
  /// Lazily creates a single `FKBadgeController` per view. Must be used from the main actor (typical for UIKit).
  @MainActor var fk_badge: FKBadgeController {
    fk_badgeControllerGetOrCreate()
  }

  /// One-line helper to show a pure dot badge.
  ///
  /// - Parameters:
  ///   - animated: Whether to fade-in when becoming visible.
  ///   - animation: Optional emphasis animation.
  @MainActor func fk_showBadgeDot(animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge.showDot(animated: animated, animation: animation)
  }

  /// One-line helper to show a numeric badge.
  ///
  /// - Parameters:
  ///   - count: Numeric value. `<= 0` hides badge under automatic policy.
  ///   - animated: Whether to fade-in when becoming visible.
  ///   - animation: Optional emphasis animation.
  @MainActor func fk_showBadgeCount(_ count: Int, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge.showCount(count, animated: animated, animation: animation)
  }

  /// One-line helper to show a text badge.
  ///
  /// - Parameters:
  ///   - text: Badge text. Whitespace-only text is treated as dot mode.
  ///   - animated: Whether to fade-in when becoming visible.
  ///   - animation: Optional emphasis animation.
  @MainActor func fk_showBadgeText(_ text: String, animated: Bool = false, animation: FKBadgeAnimation = .none) {
    fk_badge.showText(text, animated: animated, animation: animation)
  }

  /// One-line helper to hide current badge.
  ///
  /// - Parameter animated: Whether hide transition should animate.
  @MainActor func fk_hideBadge(animated: Bool = false) {
    fk_badge.clear(animated: animated)
  }
}

@MainActor
private extension UIView {
  // Runtime-associated lazy storage to avoid subclassing `UIView`.
  func fk_badgeControllerGetOrCreate() -> FKBadgeController {
    if let existing = objc_getAssociatedObject(self, &FKBadgeAssociatedKeys.controller) as? FKBadgeController {
      return existing
    }
    let created = FKBadgeController(target: self)
    objc_setAssociatedObject(self, &FKBadgeAssociatedKeys.controller, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return created
  }
}
