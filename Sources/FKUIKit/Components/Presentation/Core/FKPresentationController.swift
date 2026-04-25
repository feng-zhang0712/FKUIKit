import ObjectiveC
import UIKit

/// Entry point that wires content, configuration, and transition components together.
@MainActor
public final class FKPresentationController: NSObject {
  /// Content controller that will be presented.
  public let contentController: UIViewController
  /// Configuration describing the desired presentation behavior.
  public let configuration: FKPresentationConfiguration
  /// Optional delegate receiving lifecycle updates.
  public weak var delegate: FKPresentationControllerDelegate?
  /// Closure-based callbacks.
  public var callbacks: FKPresentationLifecycleCallbacks

  private var host: (any FKPresentationHosting)!
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
    super.init()

    // Host routing:
    // - `.anchorEmbedded` stays inside the existing hierarchy because it must preserve local z-order,
    //   touch passthrough boundaries, and anchor attachment semantics that `UIPresentationController`
    //   cannot guarantee.
    // - All other modes use UIKit custom modal presentation for system-like transitions and lifecycle.
    if case let .anchorEmbedded(embedded) = configuration.mode {
      self.host = FKEmbeddedAnchorHost(
        owner: self,
        contentController: contentController,
        configuration: configuration,
        embeddedConfiguration: embedded
      )
    } else {
      self.host = FKModalPresentationHost(owner: self, contentController: contentController, configuration: configuration)
    }
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
    guard !host.isPresented else {
      completion?()
      return
    }
    isTransitionInFlight = true
    notifyWillPresent()
    host.present(from: presentingViewController, animated: animated) { [weak self] in
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
    guard host.isPresented else {
      completion?()
      return
    }
    isTransitionInFlight = true
    notifyWillDismiss()
    host.dismiss(animated: animated) { [weak self] in
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
    // Only modal presentations support sheet detents.
    guard host is FKModalPresentationHost else { return }
    (contentController.transitioningDelegate as? FKPresentationTransitioningDelegate)?
      .activeContainerController?
      .setDetent(detent, animated: animated)
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
