import UIKit

@MainActor
enum FKToastAnimator {
  // Entrance transition used by FKToastCenter.
  static func animateIn(
    view: UIView,
    kind: FKToastKind,
    position: FKToastPosition,
    style: FKToastAnimationStyle,
    duration: TimeInterval,
    completion: (@Sendable () -> Void)? = nil
  ) {
    switch style {
    case .fade:
      // Simple alpha-in keeps motion minimal.
      view.alpha = 0
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
        view.alpha = 1
      } completion: { _ in
        completion?()
      }
    case .slide:
      // Directional translation is aligned with placement: top slides down, bottom slides up.
      let distance: CGFloat = kind == .snackbar ? 20 : 14
      switch position {
      case .top:
        view.transform = CGAffineTransform(translationX: 0, y: -distance)
      case .center:
        view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
      case .bottom:
        view.transform = CGAffineTransform(translationX: 0, y: distance)
      }
      view.alpha = 0
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
        view.alpha = 1
        view.transform = .identity
      } completion: { _ in
        completion?()
      }
    }
  }

  // Exit transition used by FKToastCenter.
  static func animateOut(
    view: UIView,
    position: FKToastPosition,
    style: FKToastAnimationStyle,
    duration: TimeInterval,
    completion: (@Sendable () -> Void)? = nil
  ) {
    switch style {
    case .fade:
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
        view.alpha = 0
      } completion: { _ in
        completion?()
      }
    case .slide:
      let distance: CGFloat = 16
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
        view.alpha = 0
        switch position {
        case .top:
          view.transform = CGAffineTransform(translationX: 0, y: -distance)
        case .center:
          view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        case .bottom:
          view.transform = CGAffineTransform(translationX: 0, y: distance)
        }
      } completion: { _ in
        completion?()
      }
    }
  }
}
