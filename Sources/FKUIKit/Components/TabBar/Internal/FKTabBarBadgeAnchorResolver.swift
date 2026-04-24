import UIKit

@MainActor
enum FKTabBarBadgeAnchorResolver {
  /// Resolves which subview should host badge overlay for a tab item.
  ///
  /// Rules:
  /// - If the tab has an icon (image/symbol), always anchor the badge on the icon element.
  /// - If the tab is text-only, anchor the badge on the text element.
  ///
  /// This rule is independent of horizontal/vertical layout direction so visual semantics stay
  /// consistent across configurations.
  static func resolveTargetView(
    button: FKButton
  ) -> UIView {
    if let imageView = resolvedPrimaryImageView(from: button) {
      return imageView
    }
    if let titleLabel = button.titleLabel {
      return titleLabel
    }
    return button
  }

  private static func resolvedPrimaryImageView(from button: FKButton) -> UIView? {
    button.leadingImageView ?? button.imageView ?? button.trailingImageView
  }
}

