import UIKit

/// Resolves a horizontal measure for Text Kit when the host view’s `bounds.width` is still zero.
@MainActor
enum FKExpandableTextMeasurementWidth {
  /// - Returns: A width to pass into layout helpers, and whether layout may later invalidate that width
  ///   (host `bounds.width` was not ready yet).
  static func resolve(for label: UILabel) -> (width: CGFloat, needsDeferredRefresh: Bool) {
    if label.bounds.width > 1 {
      return (label.bounds.width, false)
    }
    if label.preferredMaxLayoutWidth > 1 {
      return (label.preferredMaxLayoutWidth, true)
    }
    if let w = firstAncestorWidth(startingAt: label.superview) {
      return (w, true)
    }
    return (UIScreen.main.bounds.width, true)
  }

  static func resolve(for textView: UITextView) -> (width: CGFloat, needsDeferredRefresh: Bool) {
    if textView.bounds.width > 1 {
      return (textView.bounds.width, false)
    }
    if let w = firstAncestorWidth(startingAt: textView.superview) {
      return (w, true)
    }
    return (UIScreen.main.bounds.width, true)
  }

  private static func firstAncestorWidth(startingAt view: UIView?) -> CGFloat? {
    var view = view
    while let v = view {
      if v.bounds.width > 1 {
        return v.bounds.width
      }
      view = v.superview
    }
    return nil
  }
}
