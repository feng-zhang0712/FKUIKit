import UIKit

@MainActor
enum FKTabBarScrollAlignmentStrategy {
  // MARK: - Layout

  /// Computes the target content offset for keeping selected tab visible/aligned.
  ///
  /// The strategy clamps to safe scroll bounds so repeated selection changes cannot
  /// accumulate offset drift in RTL, split view, or after rotation relayout.
  static func targetOffset(
    itemFrame: CGRect,
    layout: FKTabBarLayoutConfiguration,
    scrollView: UIScrollView
  ) -> CGPoint {
    let boundsWidth = max(1, scrollView.bounds.width)
    let minX = -scrollView.adjustedContentInset.left
    let maxX = max(minX, scrollView.contentSize.width - boundsWidth + scrollView.adjustedContentInset.right)

    // UIKit stores `contentOffset.x` in a physical coordinate space that is mirrored under RTL
    // when `semanticContentAttribute` forces right-to-left. To keep behavior consistent across
    // LTR/RTL, we:
    // 1) map `contentOffset.x` and `itemFrame` into a logical LTR space,
    // 2) run the same alignment math,
    // 3) map the result back to physical coordinates.
    let isRTL = scrollView.effectiveUserInterfaceLayoutDirection == .rightToLeft
    let maxScrollable = max(0, scrollView.contentSize.width - boundsWidth)
    func toLogical(_ physicalX: CGFloat) -> CGFloat {
      guard isRTL else { return physicalX }
      return maxScrollable - physicalX
    }
    func toPhysical(_ logicalX: CGFloat) -> CGFloat {
      guard isRTL else { return logicalX }
      return maxScrollable - logicalX
    }

    let logicalMinX = min(toLogical(minX), toLogical(maxX))
    let logicalMaxX = max(toLogical(minX), toLogical(maxX))

    let logicalItem: CGRect = {
      guard isRTL else { return itemFrame }
      // Mirror item frame within the scroll view's content width.
      let mirroredMinX = scrollView.contentSize.width - itemFrame.maxX
      return CGRect(x: mirroredMinX, y: itemFrame.minY, width: itemFrame.width, height: itemFrame.height)
    }()

    var logicalX = toLogical(scrollView.contentOffset.x)

    switch layout.selectionScrollPosition {
    case .minimalVisible:
      if logicalItem.minX < logicalX {
        logicalX = logicalItem.minX - layout.contentInsets.leading
      } else if logicalItem.maxX > logicalX + boundsWidth {
        logicalX = logicalItem.maxX - boundsWidth + layout.contentInsets.trailing
      }
    case .center:
      logicalX = logicalItem.midX - boundsWidth * 0.5
    case .leading:
      logicalX = logicalItem.minX - layout.contentInsets.leading
    case .trailing:
      logicalX = logicalItem.maxX - boundsWidth + layout.contentInsets.trailing
    }

    logicalX = min(max(logicalMinX, logicalX), logicalMaxX)
    return CGPoint(x: toPhysical(logicalX), y: scrollView.contentOffset.y)
  }
}
