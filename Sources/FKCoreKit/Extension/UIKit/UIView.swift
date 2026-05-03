#if canImport(UIKit)
import UIKit

public extension UIView {
  /// Adds multiple subviews in declaration order.
  func fk_addSubviews(_ views: UIView...) {
    views.forEach(addSubview)
  }

  /// Walks the responder chain and returns the first `UIViewController`, if any.
  var fk_nearestViewController: UIViewController? {
    sequence(first: self as UIResponder?, next: { $0?.next }).first { $0 is UIViewController } as? UIViewController
  }

  /// Depth-first search for the current first responder in this subtree.
  func fk_findFirstResponder() -> UIView? {
    if isFirstResponder { return self }
    for sub in subviews {
      if let found = sub.fk_findFirstResponder() {
        return found
      }
    }
    return nil
  }

  /// Renders the view hierarchy into an image using `UIGraphicsImageRenderer`.
  func fk_snapshotImage(afterScreenUpdates: Bool = false) -> UIImage? {
    let bounds = bounds
    guard bounds.width > 0, bounds.height > 0 else { return nil }
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = isOpaque
    format.scale = window?.screen.scale ?? UIScreen.main.scale
    let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
    return renderer.image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
    }
  }

  /// Applies corner radius; optionally limits rounding to specific corners (iOS 11+).
  func fk_applyCornerRadius(_ radius: CGFloat, maskedCorners: CACornerMask? = nil) {
    layer.cornerRadius = radius
    layer.masksToBounds = true
    if let maskedCorners, #available(iOS 11.0, *) {
      layer.maskedCorners = maskedCorners
    }
  }

  /// Removes all arranged subviews from a `UIStackView` receiver.
  func fk_removeAllArrangedSubviewsIfStackView() {
    guard let stack = self as? UIStackView else { return }
    stack.arrangedSubviews.forEach {
      stack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }
}

#endif
