import UIKit

/// Container presentation controller responsible for frame calculation and backdrop wiring.
@MainActor
final class FKContainerPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
  /// Bridges interactive/detent events back to the public controller.
  weak var owner: FKPresentationController?
  /// Immutable runtime configuration snapshot for this presentation session.
  let configuration: FKPresentationConfiguration
  /// Backdrop renderer shared by supported backdrop styles.
  let backdropView = FKPresentationBackdropView()
  /// Non-interactive chrome host for grabber and related affordances.
  let chromeView = UIView()
  /// Optional blur material rendered behind the presented content (installed only when `configuration.containerBlur.isEnabled`).
  var containerBlurView: FKBlurView?
  /// Presentation shell carrying frame, corners, border, and shadow.
  let wrapperView = UIView()
  /// Content host that embeds the system provided presented view.
  let contentContainerView = UIView()
  /// Drag affordance for sheet-like layouts.
  let grabberView = UIView()
  /// Cached system-provided presented view after re-parenting into content container.
  weak var hostedPresentedView: UIView?

  lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  var resolvedDetentHeights: [CGFloat] = []
  var currentDetentIndex: Int = 0
  var panStartFrame: CGRect = .zero
  var isPanningSheet: Bool = false
  var sheetPanVelocityY: CGFloat = 0
  var keepsInteractiveFrameForDismissal = false
  var dismissalStartingFrame: CGRect = .zero

  var keyboardBottomInset: CGFloat = 0
  var keyboardObservers: [NSObjectProtocol] = []
  var originalScrollInsets: (content: UIEdgeInsets, indicator: UIEdgeInsets)?
  weak var presentingEffectHostView: UIView?

  /// Creates a container presentation controller with configuration and interaction dependencies.
  init(
    presentedViewController: UIViewController,
    presenting presentingViewController: UIViewController?,
    owner: FKPresentationController?,
    configuration: FKPresentationConfiguration
  ) {
    self.owner = owner
    self.configuration = configuration
    super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
  }

  /// We wrap the system-provided presented view to enable corner radius, shadow, transforms, and chrome.
  public override var presentedView: UIView? {
    wrapperView
  }

  public override var frameOfPresentedViewInContainerView: CGRect {
    if keepsInteractiveFrameForDismissal {
      return dismissalStartingFrame
    }
    guard let containerView else { return .zero }
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)

    switch configuration.layout {
    case .bottomSheet(_):
      let height = resolvedSheetHeight(in: containerView, bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(in: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y = bounds.height - height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0)
      return CGRect(x: x, y: y, width: width, height: height)
    case .topSheet(_):
      let height = resolvedSheetHeight(in: containerView, bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(in: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y: CGFloat = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      return CGRect(x: x, y: y, width: width, height: height)
    case .center(_):
      return resolvedCenterFrame(in: containerView, bounds: bounds, safeInsets: safeInsets)
    case .anchor:
      // Anchor-hosteds are not presented via UIPresentationController.
      // Fall back to center frame for safety if misconfigured.
      return resolvedCenterFrame(in: containerView, bounds: bounds, safeInsets: safeInsets)
    case let .edge(edge):
      return edgeFrame(in: bounds, edge: edge)
    }
  }

  public override func presentationTransitionWillBegin() {
    guard let containerView else { return }

    backdropView.frame = containerView.bounds
    backdropView.configure(with: configuration.backdropStyle)
    backdropView.alpha = 0
    containerView.insertSubview(backdropView, at: 0)

    chromeView.backgroundColor = .clear
    chromeView.isUserInteractionEnabled = false

    wrapperView.backgroundColor = .systemBackground
    // Content should be below chrome so the grabber is never covered by the presented view.
    wrapperView.addSubview(contentContainerView)
    wrapperView.addSubview(chromeView)
    contentContainerView.backgroundColor = .clear
    contentContainerView.clipsToBounds = true

    if let systemPresentedView = super.presentedViewController.view {
      hostedPresentedView?.removeFromSuperview()
      hostedPresentedView = systemPresentedView
      systemPresentedView.removeFromSuperview()
      contentContainerView.addSubview(systemPresentedView)
    }
    configureContainerBlurIfNeeded()

    currentDetentIndex = configuration.sheet.initialDetentIndex
    recalculateDetentsIfNeeded()
    configureGrabberIfNeeded()
    installGesturesIfNeeded()
    startKeyboardTrackingIfNeeded()

    configureAccessibility()
    applyPresentingViewEffectIfNeeded(isPresenting: true)

    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in
        self.updateBackdropForCurrentState()
      }
    } else {
      updateBackdropForCurrentState()
    }
  }

  public override func dismissalTransitionWillBegin() {
    super.dismissalTransitionWillBegin()
    if keepsInteractiveFrameForDismissal {
      wrapperView.frame = dismissalStartingFrame
      chromeView.frame = wrapperView.bounds
      layoutContentContainer()
      hostedPresentedView?.frame = contentContainerView.bounds
    }
    applyPresentingViewEffectIfNeeded(isPresenting: false)
    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in
        self.backdropView.alpha = 0
      }
    } else {
      backdropView.alpha = 0
    }
  }

  public override func containerViewDidLayoutSubviews() {
    super.containerViewDidLayoutSubviews()
    backdropView.frame = containerView?.bounds ?? .zero

    // During sheet dragging, keep the live interactive frame instead of snapping back to detent.
    if !isPanningSheet && !keepsInteractiveFrameForDismissal {
      wrapperView.frame = frameOfPresentedViewInContainerView
    }
    chromeView.frame = wrapperView.bounds
    layoutContentContainer()
    hostedPresentedView?.frame = contentContainerView.bounds

    applyContainerAppearance()
    if let containerView {
      applyKeyboardAvoidance(in: containerView)
    }
  }

  public override func dismissalTransitionDidEnd(_ completed: Bool) {
    super.dismissalTransitionDidEnd(completed)
    if completed {
      backdropView.removeFromSuperview()
      stopKeyboardTracking()
      cleanupPresentingViewEffect()
      resetDismissalFrameLock()
    } else {
      // Interactive dismiss can cancel after intermediate visual changes; restore backdrop/effect state
      // so the re-presented sheet remains visually consistent and does not look half-dismissed.
      applyPresentingViewEffectIfNeeded(isPresenting: true)
      updateBackdropForCurrentState()
      resetDismissalFrameLock()
    }
  }

  public override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
    super.preferredContentSizeDidChange(forChildContentContainer: container)
    guard let containerView else { return }
    recalculateDetentsIfNeeded()
    let targetFrame = frameOfPresentedViewInContainerView
    let applyLayout: () -> Void = {
      self.wrapperView.frame = targetFrame
      self.chromeView.frame = self.wrapperView.bounds
      self.layoutContentContainer()
      self.hostedPresentedView?.frame = self.contentContainerView.bounds
      self.applyContainerAppearance()
      self.applyKeyboardAvoidance(in: containerView)
      self.updateBackdropForCurrentState()
      self.wrapperView.layoutIfNeeded()
    }

    // Keep fit-content updates close to system sheet behavior by animating size transitions.
    if presentedViewController.transitionCoordinator == nil {
      UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: applyLayout)
    } else {
      applyLayout()
    }
  }

  private func resetDismissalFrameLock() {
    keepsInteractiveFrameForDismissal = false
    dismissalStartingFrame = .zero
  }
}

