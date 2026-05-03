#if canImport(UIKit)
import UIKit

public extension UIStackView {
  /// Removes every arranged subview from the stack and its superview.
  func fk_removeAllArrangedSubviews() {
    arrangedSubviews.forEach {
      removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }

  /// Replaces the arranged subviews with `views`, preserving the stack’s axis and spacing.
  func fk_setArrangedSubviews(_ views: [UIView]) {
    fk_removeAllArrangedSubviews()
    views.forEach(addArrangedSubview)
  }
}

#endif
