import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Backdrop Alpha

  /// Recomputes backdrop alpha using static style or detent-progress interpolation.
  func updateBackdropForCurrentState() {
    guard configuration.sheet.multiStageBackdrop.isEnabled else {
      // Respect configured backdrop intensity when multi-stage interpolation is disabled.
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

  /// Applies optional presenting-view scale effect during transitions.
  func applyPresentingViewEffectIfNeeded(isPresenting: Bool) {
    let effect = configuration.presentingViewEffect
    guard effect.isEnabled, let host = presentingViewController.view else { return }
    if isPresenting, host.window == nil {
      // Presenting controller is disappearing; skip effect safely.
      cleanupPresentingViewEffect()
      return
    }
    presentingEffectHostView = host

    let updates = {
      host.transform = isPresenting ? CGAffineTransform(scaleX: effect.scale, y: effect.scale) : .identity
    }
    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in updates() }
    } else {
      updates()
    }
  }

  /// Resets presenting-view transforms.
  func cleanupPresentingViewEffect() {
    presentingEffectHostView?.transform = .identity
    presentingEffectHostView = nil
  }
}
