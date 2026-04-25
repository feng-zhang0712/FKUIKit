import UIKit

/// Supplies custom transition animators for presentation and dismissal.
public protocol FKPresentationAnimatorProviding {
  /// Returns an animator used when content is being presented.
  func makePresentationAnimator() -> UIViewControllerAnimatedTransitioning
  /// Returns an animator used when content is being dismissed.
  func makeDismissalAnimator() -> UIViewControllerAnimatedTransitioning
}
