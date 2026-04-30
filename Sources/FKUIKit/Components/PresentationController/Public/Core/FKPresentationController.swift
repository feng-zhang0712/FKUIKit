import ObjectiveC
import UIKit

/// Entry point that wires content, configuration, and transition components together.
@MainActor
public final class FKPresentationController: NSObject {
  public enum State: Equatable {
    case idle
    case presenting
    case presented
    case dismissing
  }

  /// Content controller that will be presented.
  public let contentController: UIViewController
  /// Configuration describing the desired presentation behavior.
  public let configuration: FKPresentationConfiguration
  /// Optional delegate receiving lifecycle updates.
  public weak var delegate: FKPresentationControllerDelegate?
  /// Closure-based lifecycle handlers.
  public var handlers: FKPresentationLifecycleHandlers
  /// Current controller state.
  public private(set) var state: State = .idle
  /// Whether content is currently visible.
  public var isPresented: Bool { state == .presented }
  /// Whether a transition is running.
  public var isTransitioning: Bool { state == .presenting || state == .dismissing }
  /// Current active detent when sheet modes are used.
  public private(set) var currentDetent: FKPresentationDetent?
  /// Current detent index when sheet modes are used.
  public private(set) var currentDetentIndex: Int?
  /// Available detents for sheet modes.
  public var availableDetents: [FKPresentationDetent] { configuration.sheet.detents }

  private var host: (any FKPresentationHost)!

  /// Creates a presentation controller without presenting it immediately.
  public init(
    contentController: UIViewController,
    configuration: FKPresentationConfiguration = .default,
    delegate: FKPresentationControllerDelegate? = nil,
    handlers: FKPresentationLifecycleHandlers = .init()
  ) {
    self.contentController = contentController
    self.configuration = configuration
    self.delegate = delegate
    self.handlers = handlers
    super.init()

    // Host routing:
    // - `.anchor` stays inside the existing hierarchy because it must preserve local z-order,
    //   touch passthrough boundaries, and anchor attachment semantics that `UIPresentationController`
    //   cannot guarantee.
    // - All other modes use UIKit custom modal presentation for system-like transitions and lifecycle.
    if case let .anchor(anchorConfig) = configuration.layout {
      self.host = FKAnchorHost(
        owner: self,
        contentController: contentController,
        configuration: configuration,
        anchorConfiguration: anchorConfig
      )
    } else {
      self.host = FKModalPresentationHost(owner: self, contentController: contentController, configuration: configuration)
    }
  }

  /// Presents content from a source view controller.
  public func present(from presentingViewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
    guard assertMainThread("present", completion: completion) else { return }
    guard !isTransitioning else {
      completion?()
      return
    }
    guard !host.isPresented else {
      completion?()
      return
    }
    state = .presenting
    notifyWillPresent()
    host.present(from: presentingViewController, animated: animated) { [weak self] in
      self?.state = .presented
      self?.notifyDidPresent()
      completion?()
    }
  }

  /// Dismisses presented content if currently visible.
  public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard assertMainThread("dismiss", completion: completion) else { return }
    guard !isTransitioning else {
      completion?()
      return
    }
    guard host.isPresented else {
      completion?()
      return
    }
    state = .dismissing
    notifyWillDismiss()
    host.dismiss(animated: animated) { [weak self] in
      self?.state = .idle
      self?.notifyDidDismiss()
      completion?()
    }
  }

  /// Programmatically switches to a target detent when the active mode supports sheet detents.
  public func setDetent(_ detent: FKPresentationDetent, animated: Bool = true) {
    guard assertMainThread("setDetent") else { return }
    if let index = configuration.sheet.detents.firstIndex(of: detent) {
      setDetent(index: index, animated: animated)
    }
  }

  /// Programmatically switches to a detent index when sheet modes are active.
  public func setDetent(index: Int, animated: Bool = true) {
    guard assertMainThread("setDetent(index:)") else { return }
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
    handlers: FKPresentationLifecycleHandlers = .init(),
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) -> FKPresentationController {
    let controller = FKPresentationController(
      contentController: contentController,
      configuration: configuration,
      delegate: delegate,
      handlers: handlers
    )
    controller.present(from: presentingViewController, animated: animated, completion: completion)
    return controller
  }

  func notifyProgress(_ progress: CGFloat) {
    delegate?.presentationController(self, didUpdateProgress: progress)
    handlers.progress?(progress)
  }

  func notifyDetentDidChange(_ detent: FKPresentationDetent, index: Int) {
    currentDetent = detent
    currentDetentIndex = index
    delegate?.presentationController(self, didChangeDetent: detent, index: index)
    handlers.detentDidChange?(detent, index)
  }

  func notifyWillPresent() {
    delegate?.presentationControllerWillPresent(self)
    handlers.willPresent?()
  }

  func notifyDidPresent() {
    delegate?.presentationControllerDidPresent(self)
    handlers.didPresent?()
  }

  func notifyWillDismiss() {
    delegate?.presentationControllerWillDismiss(self)
    handlers.willDismiss?()
  }

  func notifyDidDismiss() {
    delegate?.presentationControllerDidDismiss(self)
    handlers.didDismiss?()
  }

  private func assertMainThread(_ operation: String, completion: (() -> Void)? = nil) -> Bool {
    guard Thread.isMainThread else {
      assertionFailure("FKPresentationController.\(operation) must be called on the main thread.")
      completion?()
      return false
    }
    return true
  }
}
