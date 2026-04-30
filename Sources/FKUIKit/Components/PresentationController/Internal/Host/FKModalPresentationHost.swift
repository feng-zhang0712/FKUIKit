import ObjectiveC
import UIKit

@MainActor
final class FKModalPresentationHost: NSObject, FKPresentationHost {
  private static var associationKey: UInt8 = 0

  private unowned let owner: FKPresentationController
  private let contentController: UIViewController
  private let configuration: FKPresentationConfiguration
  private let transitioningDelegateBox: FKPresentationTransitioningDelegate

  private(set) var isPresented: Bool = false

  init(owner: FKPresentationController, contentController: UIViewController, configuration: FKPresentationConfiguration) {
    self.owner = owner
    self.contentController = contentController
    self.configuration = configuration
    self.transitioningDelegateBox = FKPresentationTransitioningDelegate(configuration: configuration)
    super.init()

    transitioningDelegateBox.owner = owner
    // Modal path relies on UIKit custom presentation so we configure style/delegate once up front.
    contentController.modalPresentationStyle = .custom
    contentController.transitioningDelegate = transitioningDelegateBox
    objc_setAssociatedObject(
      contentController,
      &Self.associationKey,
      transitioningDelegateBox,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    guard contentController.presentingViewController == nil else {
      completion?()
      return
    }
    isPresented = true
    presentingViewController.present(contentController, animated: animated, completion: completion)
  }

  func dismiss(animated: Bool, completion: (() -> Void)?) {
    guard contentController.presentingViewController != nil else {
      completion?()
      return
    }
    isPresented = false
    contentController.dismiss(animated: animated, completion: completion)
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    // Modal path updates via UIPresentationController layout lifecycle.
  }
}

