import CoreGraphics
import Foundation

public extension CGSize {
  /// Area `width * height`.
  var fk_area: CGFloat {
    width * height
  }

  /// Aspect ratio `width / height`; returns `0` when `height` is `0`.
  var fk_aspectRatio: CGFloat {
    guard height != 0 else { return 0 }
    return width / height
  }

  /// Rounds both dimensions to pixel boundaries.
  func fk_roundedToPixel(scale: CGFloat) -> CGSize {
    CGSize(width: width.fk_roundedToPixel(scale: scale), height: height.fk_roundedToPixel(scale: scale))
  }

  /// Insets the size by subtracting horizontal and vertical margins (clamped at `0`).
  func fk_insetBy(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> CGSize {
    CGSize(
      width: max(0, width - left - right),
      height: max(0, height - top - bottom)
    )
  }
}
