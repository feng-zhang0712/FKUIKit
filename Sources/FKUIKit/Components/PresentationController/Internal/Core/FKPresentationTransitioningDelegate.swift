import UIKit

/// Internal transitioning delegate that builds presentation controller and animators.
final class FKPresentationTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  weak var owner: FKPresentationController?
  weak var activeContainerController: FKContainerPresentationController?

  private let configuration: FKPresentationConfiguration

  init(configuration: FKPresentationConfiguration) {
    self.configuration = configuration
    super.init()
  }

  func presentationController(
    forPresented presented: UIViewController,
    presenting: UIViewController?,
    source: UIViewController
  ) -> UIPresentationController? {
    let controller = FKContainerPresentationController(
      presentedViewController: presented,
      presenting: presenting,
      owner: owner,
      configuration: configuration
    )
    activeContainerController = controller
    return controller
  }

  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController)
    -> (any UIViewControllerAnimatedTransitioning)? {
    if let provider = configuration.animation.customAnimatorProvider {
      return provider.makePresentationAnimator()
    }
    return FKPresentationAnimator(
      isPresentation: true,
      layout: configuration.layout,
      animationConfiguration: configuration.animation
    )
  }

  func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
    if let provider = configuration.animation.customAnimatorProvider {
      return provider.makeDismissalAnimator()
    }
    return FKPresentationAnimator(
      isPresentation: false,
      layout: configuration.layout,
      animationConfiguration: configuration.animation
    )
  }
}
