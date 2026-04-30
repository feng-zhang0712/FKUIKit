import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Backdrop Alpha

  /// Recomputes backdrop alpha using static style or detent-progress interpolation.
  func updateBackdropForCurrentState() {
    guard configuration.sheet.multiStageBackdrop.isEnabled else {
      // Respect the configured backdrop intensity. `FKPresentationBackdropView` also uses internal alpha
      // for blur effects, so we keep the container-level alpha as the primary dimming channel only.
      switch configuration.backdropStyle {
      case let .dim(_, alpha):
        backdropView.alpha = alpha
      default:
        backdropView.alpha = 1
      }
      return
    }
    guard let minHeight = resolvedDetentHeights.min(), let maxHeight = resolvedDetentHeights.max(), maxHeight > minHeight else {
      backdropView.alpha = configuration.sheet.multiStageBackdrop.maximumAlpha
      return
    }

    let currentHeight: CGFloat
    switch configuration.layout {
    case .bottomSheet(_):
      if let containerView {
        let bottomInset = configuration.safeAreaPolicy == .containerRespectsSafeArea ? containerView.safeAreaInsets.bottom : 0
        currentHeight = containerView.bounds.height - wrapperView.frame.minY - bottomInset
      } else {
        currentHeight = wrapperView.frame.height
      }
    default:
      currentHeight = wrapperView.frame.height
    }

    let rawProgress = (currentHeight - minHeight) / max(1, maxHeight - minHeight)
    let progress = min(max(rawProgress, 0), 1)
    let low = configuration.sheet.multiStageBackdrop.minimumAlpha
    let high = configuration.sheet.multiStageBackdrop.maximumAlpha
    backdropView.alpha = low + (high - low) * progress
  }

  // MARK: - Presenting View Effects

  /// Applies optional scale/blur effects to the presenting view during transitions.
  func applyPresentingViewEffectIfNeeded(isPresenting: Bool) {
    let effect = configuration.presentingViewEffect
    guard effect.isEnabled, let host = presentingViewController.view else { return }
    if isPresenting, host.window == nil {
      // Presenting controller is disappearing; skip effect safely.
      cleanupPresentingViewEffect()
      return
    }
    presentingEffectHostView = host

    if let style = effect.blurStyle, presentingBlurView == nil {
      let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
      blurView.frame = host.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blurView.alpha = 0
      host.addSubview(blurView)
      presentingBlurView = blurView
    }

    let updates = {
      host.transform = isPresenting ? CGAffineTransform(scaleX: effect.scale, y: effect.scale) : .identity
      self.presentingBlurView?.alpha = isPresenting ? effect.blurAlpha : 0
    }
    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in updates() }
    } else {
      updates()
    }
  }

  /// Resets presenting-view transforms and temporary blur views.
  func cleanupPresentingViewEffect() {
    presentingEffectHostView?.transform = .identity
    presentingBlurView?.removeFromSuperview()
    presentingBlurView = nil
    presentingEffectHostView = nil
  }
}
