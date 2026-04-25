import ObjectiveC
import UIKit

/// Entry point that wires content, configuration, and transition components together.
@MainActor
public final class FKPresentationController: NSObject {
  private static var associationKey: UInt8 = 0

  /// Content controller that will be presented.
  public let contentController: UIViewController
  /// Configuration describing the desired presentation behavior.
  public let configuration: FKPresentationConfiguration
  /// Optional delegate receiving lifecycle updates.
  public weak var delegate: FKPresentationControllerDelegate?
  /// Closure-based callbacks.
  public var callbacks: FKPresentationLifecycleCallbacks

  private let transitioningDelegateBox: FKPresentationTransitioningDelegate
  private var isTransitionInFlight = false

  /// Creates a presentation controller without presenting it immediately.
  public init(
    contentController: UIViewController,
    configuration: FKPresentationConfiguration = .default,
    delegate: FKPresentationControllerDelegate? = nil,
    callbacks: FKPresentationLifecycleCallbacks = .init()
  ) {
    self.contentController = contentController
    self.configuration = configuration
    self.delegate = delegate
    self.callbacks = callbacks
    self.transitioningDelegateBox = FKPresentationTransitioningDelegate(configuration: configuration)
    super.init()

    transitioningDelegateBox.owner = self
    contentController.modalPresentationStyle = .custom
    contentController.transitioningDelegate = transitioningDelegateBox
    // Keep transitioning delegate alive for the full transition lifecycle.
    objc_setAssociatedObject(
      contentController,
      &Self.associationKey,
      transitioningDelegateBox,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  /// Presents content from a source view controller.
  public func present(from presentingViewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
    guard Thread.isMainThread else {
      assertionFailure("FKPresentationController.present must be called on the main thread.")
      completion?()
      return
    }
    guard !isTransitionInFlight else {
      completion?()
      return
    }
    guard contentController.presentingViewController == nil else {
      completion?()
      return
    }
    isTransitionInFlight = true
    notifyWillPresent()
    presentingViewController.present(contentController, animated: animated) { [weak self] in
      self?.isTransitionInFlight = false
      self?.notifyDidPresent()
      completion?()
    }
  }

  /// Dismisses presented content if currently visible.
  public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard Thread.isMainThread else {
      assertionFailure("FKPresentationController.dismiss must be called on the main thread.")
      completion?()
      return
    }
    guard !isTransitionInFlight else {
      completion?()
      return
    }
    guard contentController.presentingViewController != nil else {
      completion?()
      return
    }
    isTransitionInFlight = true
    notifyWillDismiss()
    contentController.dismiss(animated: animated) { [weak self] in
      self?.isTransitionInFlight = false
      self?.notifyDidDismiss()
      completion?()
    }
  }

  /// Programmatically switches to a target detent when the active mode supports sheet detents.
  public func setDetent(_ detent: FKPresentationDetent, animated: Bool = true) {
    guard Thread.isMainThread else {
      assertionFailure("FKPresentationController.setDetent must be called on the main thread.")
      return
    }
    transitioningDelegateBox.activeContainerController?.setDetent(detent, animated: animated)
  }

  /// Convenience API for one-line presentation.
  @discardableResult
  public static func present(
    contentController: UIViewController,
    from presentingViewController: UIViewController,
    configuration: FKPresentationConfiguration = .default,
    delegate: FKPresentationControllerDelegate? = nil,
    callbacks: FKPresentationLifecycleCallbacks = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) -> FKPresentationController {
    let controller = FKPresentationController(
      contentController: contentController,
      configuration: configuration,
      delegate: delegate,
      callbacks: callbacks
    )
    controller.present(from: presentingViewController, animated: animated, completion: completion)
    return controller
  }

  func notifyProgress(_ progress: CGFloat) {
    delegate?.presentationController(self, didUpdateProgress: progress)
    callbacks.progress?(progress)
  }

  func notifyDetentDidChange(_ detent: FKPresentationDetent, index: Int) {
    delegate?.presentationController(self, didChangeDetent: detent, index: index)
    callbacks.detentDidChange?(detent, index)
  }

  func notifyWillPresent() {
    delegate?.presentationControllerWillPresent(self)
    callbacks.willPresent?()
  }

  func notifyDidPresent() {
    delegate?.presentationControllerDidPresent(self)
    callbacks.didPresent?()
  }

  func notifyWillDismiss() {
    delegate?.presentationControllerWillDismiss(self)
    callbacks.willDismiss?()
  }

  func notifyDidDismiss() {
    delegate?.presentationControllerDidDismiss(self)
    callbacks.didDismiss?()
  }
}
