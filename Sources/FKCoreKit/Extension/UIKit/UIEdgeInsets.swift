#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIEdgeInsets {
  /// Uniform insets where every edge uses the same value.
  static func fk_all(_ value: CGFloat) -> UIEdgeInsets {
    UIEdgeInsets(top: value, left: value, bottom: value, right: value)
  }

  /// Horizontal-only insets (`left` and `right`).
  static func fk_horizontal(_ value: CGFloat) -> UIEdgeInsets {
    UIEdgeInsets(top: 0, left: value, bottom: 0, right: value)
  }

  /// Vertical-only insets (`top` and `bottom`).
  static func fk_vertical(_ value: CGFloat) -> UIEdgeInsets {
    UIEdgeInsets(top: value, left: 0, bottom: value, right: 0)
  }

  /// Sum of `left` and `right`.
  var fk_horizontalTotal: CGFloat {
    left + right
  }

  /// Sum of `top` and `bottom`.
  var fk_verticalTotal: CGFloat {
    top + bottom
  }

  /// Insets another inset struct component-wise.
  func fk_inset(by other: UIEdgeInsets) -> UIEdgeInsets {
    UIEdgeInsets(
      top: top + other.top,
      left: left + other.left,
      bottom: bottom + other.bottom,
      right: right + other.right
    )
  }
}

#endif
