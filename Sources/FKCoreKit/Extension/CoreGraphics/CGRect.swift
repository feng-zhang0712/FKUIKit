import CoreGraphics
import Foundation

public extension CGRect {
  /// Center point of the rectangle.
  var fk_center: CGPoint {
    CGPoint(x: midX, y: midY)
  }

  /// `true` when width and height are both positive.
  var fk_hasPositiveArea: Bool {
    width > 0 && height > 0
  }

  /// Insets the rect symmetrically by `delta` on all sides.
  func fk_insetBy(_ delta: CGFloat) -> CGRect {
    insetBy(dx: delta, dy: delta)
  }

  /// Expands the rect symmetrically by `delta` on all sides.
  func fk_outsetBy(_ delta: CGFloat) -> CGRect {
    insetBy(dx: -delta, dy: -delta)
  }

  /// Returns `true` when `self` fully contains `other` as a rectangle (not only the center point).
  func fk_fullyContains(_ other: CGRect) -> Bool {
    contains(other)
  }
}
