#if canImport(UIKit)
import UIKit

public extension UIScrollView {
  /// Scrolls to the top-left content offset respecting `adjustedContentInset`.
  func fk_scrollToTop(animated: Bool) {
    let top = -adjustedContentInset.top
    setContentOffset(CGPoint(x: -adjustedContentInset.left, y: top), animated: animated)
  }

  /// Scrolls as close to the bottom as allowed by `contentSize` and insets.
  func fk_scrollToBottom(animated: Bool) {
    let bottomY = max(-adjustedContentInset.top, contentSize.height - bounds.height + adjustedContentInset.bottom)
    setContentOffset(CGPoint(x: contentOffset.x, y: bottomY), animated: animated)
  }

  /// `true` when the user has scrolled away from the top by more than `threshold`.
  func fk_isScrolledPastTop(threshold: CGFloat = 1) -> Bool {
    contentOffset.y > -adjustedContentInset.top + threshold
  }
}

#endif
