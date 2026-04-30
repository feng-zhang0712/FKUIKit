import UIKit

/// Percent-driven interaction controller used for swipe dismissal.
final class FKPresentationDismissInteractionController: UIPercentDrivenInteractiveTransition {
  /// Indicates whether an interactive dismissal is currently in progress.
  var isInteracting = false

  override init() {
    super.init()
    completionCurve = .easeOut
    completionSpeed = 1
  }

  func beginDismissal(from viewController: UIViewController) {
    guard !isInteracting else { return }
    isInteracting = true
    viewController.dismiss(animated: true)
  }

  func updateDismissal(progress: CGFloat) {
    update(min(max(progress, 0), 1))
  }

  func finishDismissal() {
    guard isInteracting else { return }
    finish()
    isInteracting = false
  }

  func cancelDismissal() {
    guard isInteracting else { return }
    cancel()
    isInteracting = false
  }
}
