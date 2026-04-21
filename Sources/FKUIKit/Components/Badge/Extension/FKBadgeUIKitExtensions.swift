import UIKit

public extension UIButton {
  /// Shortcut to the shared UIView-based badge controller.
  ///
  /// Use this when you want controller-level APIs (`setAnchor`, `playAnimation`, `onTap`, etc.).
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}

public extension UILabel {
  /// Shortcut to the shared UIView-based badge controller.
  ///
  /// Useful for inline labels that need consistent badge control APIs.
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}

public extension UIImageView {
  /// Shortcut to the shared UIView-based badge controller.
  ///
  /// Commonly used for avatar/status overlays.
  @MainActor var fk_badgeController: FKBadgeController { fk_badge }
}
