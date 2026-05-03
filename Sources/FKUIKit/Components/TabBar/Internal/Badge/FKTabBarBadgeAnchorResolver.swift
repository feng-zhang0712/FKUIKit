import UIKit

@MainActor
enum FKTabBarBadgeAnchorResolver {
  /// Resolves which subview should host badge overlay for a tab item.
  ///
  /// Rules (to reduce overlap with icon/text):
  /// - If there is only one visible content element, anchor badge on that element.
  /// - When there are multiple elements:
  ///   - Vertical axis: anchor on the first element (top-most).
  ///   - Horizontal axis: anchor on the last element (trailing-most).
  static func resolveTargetView(
    button: FKButton
  ) -> UIView {
    let imageView = resolvedPrimaryImageView(from: button)
    let titleLabel = button.titleLabel
    let subtitleLabel = button.subtitleLabel

    // Collect "major" content elements in axis order.
    // Note: subtitle is typically rendered under title; we treat it as a fallback text element.
    let textView: UIView? = titleLabel ?? subtitleLabel

    switch button.axis {
    case .vertical:
      // First element wins.
      if let imageView, textView != nil { return imageView }
      if let imageView { return imageView }
      if let textView { return textView }
      return button

    case .horizontal:
      // Last element wins.
      if let imageView, let textView { return textView }
      if let textView { return textView }
      if let imageView { return imageView }
      return button
    }
  }

  private static func resolvedPrimaryImageView(from button: FKButton) -> UIView? {
    button.leadingImageView ?? button.imageView ?? button.trailingImageView
  }
}

