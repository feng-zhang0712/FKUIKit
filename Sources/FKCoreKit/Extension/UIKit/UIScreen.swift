#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIScreen {
  /// One logical point expressed in pixels for this screen (`1 / scale`).
  var fk_onePixelInPoints: CGFloat {
    1.0 / scale
  }

  /// Native pixel dimensions of the screen bounds.
  var fk_nativePixelBounds: CGRect {
    nativeBounds
  }
}

#endif
