import UIKit

/// Full-screen hit-test filter for optional touch interception.
final class FKToastBlockingView: UIView {
  var passthroughRects: [CGRect] = []

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    for rect in passthroughRects where rect.contains(point) {
      return false
    }
    return true
  }
}
