import UIKit

@MainActor
enum FKTopNotificationAnimator {
  // Performs the entrance animation for the notification card.
  static func animateIn(
    view: UIView,
    style: FKTopNotificationAnimationStyle,
    duration: TimeInterval,
    curve: FKTopNotificationAnimationCurve,
    completion: (@Sendable () -> Void)? = nil
  ) {
    switch style {
    case .fade:
      // Fade in with no translation for minimal motion.
      view.alpha = 0
      UIView.animate(withDuration: duration, delay: 0, options: curve.options) {
        view.alpha = 1
      } completion: { _ in completion?() }
    case .slide:
      // Start slightly above the final position, then slide down with alpha.
      view.alpha = 0
      view.transform = CGAffineTransform(translationX: 0, y: -18)
      UIView.animate(withDuration: duration, delay: 0, options: curve.options) {
        view.alpha = 1
        view.transform = .identity
      } completion: { _ in completion?() }
    }
  }

  static func animateOut(
    view: UIView,
    style: FKTopNotificationAnimationStyle,
    duration: TimeInterval,
    curve: FKTopNotificationAnimationCurve,
    completion: (@Sendable () -> Void)? = nil
  ) {
    switch style {
    case .fade:
      // Fade out in place.
      UIView.animate(withDuration: duration, delay: 0, options: curve.options) {
        view.alpha = 0
      } completion: { _ in completion?() }
    case .slide:
      // Fade and translate upward for a top-dismiss effect.
      UIView.animate(withDuration: duration, delay: 0, options: curve.options) {
        view.alpha = 0
        view.transform = CGAffineTransform(translationX: 0, y: -14)
      } completion: { _ in completion?() }
    }
  }
}
