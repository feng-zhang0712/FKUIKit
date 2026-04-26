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
  /// Whether content is currently visible.
  public private(set) var isPresented: Bool = false
  /// Whether a transition is running.
  public private(set) var isTransitioning: Bool = false
  /// Current active detent when sheet modes are used.
  public private(set) var currentDetent: FKPresentationDetent?
  /// Current detent index when sheet modes are used.
  public private(set) var currentDetentIndex: Int?
  /// Available detents for sheet modes.
  public var availableDetents: [FKPresentationDetent] { configuration.sheet.detents }

  private var host: (any FKPresentationHosting)!

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
    guard !isTransitioning else {
      completion?()
      return
    }
    guard !host.isPresented else {
      completion?()
      return
    }
    isTransitioning = true
    notifyWillPresent()
    host.present(from: presentingViewController, animated: animated) { [weak self] in
      self?.isTransitioning = false
      self?.isPresented = true
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
    guard !isTransitioning else {
      completion?()
      return
    }
    guard host.isPresented else {
      completion?()
      return
    }
    isTransitioning = true
    notifyWillDismiss()
    host.dismiss(animated: animated) { [weak self] in
      self?.isTransitioning = false
      self?.isPresented = false
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
    if let index = configuration.sheet.detents.firstIndex(of: detent) {
      setDetent(index: index, animated: animated)
    }
  }

  /// Programmatically switches to a detent index when sheet modes are active.
  public func setDetent(index: Int, animated: Bool = true) {
    guard Thread.isMainThread else {
      assertionFailure("FKPresentationController.setDetent(index:) must be called on the main thread.")
      return
    }
    guard host is FKModalPresentationHost else { return }
    let clamped = max(0, min(index, max(0, configuration.sheet.detents.count - 1)))
    guard configuration.sheet.detents.indices.contains(clamped) else { return }
    (contentController.transitioningDelegate as? FKPresentationTransitioningDelegate)?
      .activeContainerController?
      .setDetent(configuration.sheet.detents[clamped], animated: animated)
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
    currentDetent = detent
    currentDetentIndex = index
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
