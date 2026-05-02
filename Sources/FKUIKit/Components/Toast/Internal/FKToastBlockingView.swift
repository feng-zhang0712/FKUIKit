import UIKit

/// Transparent full-screen receiver when `interceptTouches` is on; honors `passthroughRects`.
final class FKToastBlockingView: UIView {
  var passthroughRects: [CGRect] = []

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    for rect in passthroughRects where rect.contains(point) {
      return false
    }
    return true
  }
}
