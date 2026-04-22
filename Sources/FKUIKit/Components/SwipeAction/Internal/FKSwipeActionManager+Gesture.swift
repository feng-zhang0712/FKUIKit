import UIKit

@MainActor
extension FKSwipeActionManager: UIGestureRecognizerDelegate {
  /// Determines whether the gesture recognizer should begin.
  ///
  /// - Parameter gestureRecognizer: The gesture recognizer requesting permission.
  /// - Returns: `true` when the interaction should start; otherwise `false`.
  ///
  /// - Note: FKSwipeAction only begins when the user intent is primarily horizontal,
  ///   so vertical scrolling remains smooth and non-invasive.
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard isEnabled else { return false }
    guard let scrollView else { return false }

    if gestureRecognizer === pan, let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let v = pan.velocity(in: scrollView)
      // Prefer horizontal, and ignore tiny movements to keep scrolling fluid.
      return abs(v.x) > abs(v.y) && abs(v.x) > 30
    }

    if gestureRecognizer === tap {
      // Only enable tap-to-close when we have an opened cell.
      return configuration.tapToClose && openedCell != nil
    }
    return true
  }

  /// Asks whether a touch should be received by the gesture recognizer.
  ///
  /// - Parameters:
  ///   - gestureRecognizer: The gesture recognizer evaluating the touch.
  ///   - touch: The touch object.
  /// - Returns: `true` to receive the touch; otherwise `false`.
  ///
  /// - Important: Taps on action buttons must not be intercepted by the tap-to-close recognizer.
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    // Do not intercept taps on action buttons.
    if let view = touch.view, view is FKSwipeActionButtonView || view.isDescendant(ofClassNamed: "FKSwipeActionButtonView") {
      return false
    }
    return true
  }

  /// Allows simultaneous recognition with other gestures (e.g. vertical scrolling).
  ///
  /// - Parameters:
  ///   - gestureRecognizer: The gesture recognizer on FKSwipeAction.
  ///   - otherGestureRecognizer: Another gesture recognizer.
  /// - Returns: `true` to recognize simultaneously.
  ///
  /// - Note: FKSwipeAction relies on `gestureRecognizerShouldBegin` to filter intent,
  ///   and allows simultaneous recognition to keep scrolling responsive.
  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    // Allow vertical scrolling to work smoothly while we handle horizontal intent.
    true
  }
}

