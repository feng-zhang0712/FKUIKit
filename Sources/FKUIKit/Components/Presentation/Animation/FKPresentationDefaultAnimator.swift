import UIKit

/// Default animator used when no custom animator provider is supplied.
final class FKPresentationDefaultAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private let isPresentation: Bool
  private let mode: FKPresentationMode
  private let duration: TimeInterval

  init(isPresentation: Bool, mode: FKPresentationMode, duration: TimeInterval) {
    self.isPresentation = isPresentation
    self.mode = mode
    self.duration = duration
    super.init()
  }

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    duration
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    let key: UITransitionContextViewControllerKey = isPresentation ? .to : .from
    guard let controller = transitionContext.viewController(forKey: key) else {
      transitionContext.completeTransition(false)
      return
    }

    let containerView = transitionContext.containerView
    let animationView: UIView
    if isPresentation {
      guard let toView = transitionContext.view(forKey: .to) else {
        transitionContext.completeTransition(false)
        return
      }
      containerView.addSubview(toView)
      animationView = toView
    } else {
      guard let fromView = transitionContext.view(forKey: .from) else {
        transitionContext.completeTransition(false)
        return
      }
      animationView = fromView
    }

    let finalFrame = transitionContext.finalFrame(for: controller)
    if isPresentation {
      animationView.frame = initialFrame(for: finalFrame)
      animationView.alpha = usesFadeForCenterMode ? 0 : 1
    }

    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: 0.92,
      initialSpringVelocity: 0,
      options: [.curveEaseOut, .allowUserInteraction]
    ) {
      if self.isPresentation {
        animationView.frame = finalFrame
        animationView.alpha = 1
      } else {
        animationView.frame = self.initialFrame(for: finalFrame)
        animationView.alpha = self.usesFadeForCenterMode ? 0 : 1
      }
    } completion: { finished in
      transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
    }
  }

  private func initialFrame(for finalFrame: CGRect) -> CGRect {
    switch mode {
    case .bottomSheet:
      return finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
    case .topSheet:
      return finalFrame.offsetBy(dx: 0, dy: -finalFrame.height)
    case .center:
      return finalFrame.insetBy(dx: finalFrame.width * 0.06, dy: finalFrame.height * 0.06)
    case .anchor:
      return finalFrame.offsetBy(dx: 0, dy: 8)
    case let .edge(edge):
      if edge.contains(.left) { return finalFrame.offsetBy(dx: -finalFrame.width, dy: 0) }
      if edge.contains(.right) { return finalFrame.offsetBy(dx: finalFrame.width, dy: 0) }
      if edge.contains(.top) { return finalFrame.offsetBy(dx: 0, dy: -finalFrame.height) }
      return finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
    }
  }

  private var usesFadeForCenterMode: Bool {
    if case .center = mode { return true }
    return false
  }
}
