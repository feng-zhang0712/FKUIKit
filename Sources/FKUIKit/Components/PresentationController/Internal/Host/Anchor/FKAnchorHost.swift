import UIKit

@MainActor
final class FKAnchorHost: NSObject, FKPresentationHost {
  /*
   Anchor-host behavior notes
   --------------------------
   - Host container defaults to the anchor's resolved container (not window-level).
   - Insertion places presentation above other subviews and mask below it; the anchor (or its direct host child)
     is then brought to front on reposition.
   - Geometry keeps the presentation edge attached to the anchor edge with zero vertical spacing by default.
   - Default mask coverage only includes the region *below sourceView* (not full screen).
   - Animation is edge-attached (sheet-like), not alert-like scaling.
   - Corners/shadow round the free edge and follow free-edge shadow behavior.
   */
  private unowned let owner: FKPresentationController
  private let contentController: UIViewController
  private let configuration: FKPresentationConfiguration
  private let anchorConfiguration: FKAnchorConfiguration

  private(set) var isPresented: Bool = false

  private weak var presentingViewController: UIViewController?
  private weak var parentViewController: UIViewController?
  private weak var hostView: UIView?
  private weak var directAnchorChild: UIView?
  private weak var sourceView: UIView?

  private var anchorHostViewController: FKAnchorHostViewController?

  private let repositionCoordinator = FKAnchorRepositionCoordinator()
  private var orientationObserver: NSObjectProtocol?
  private var keyboardObservers: [NSObjectProtocol] = []
  private var keyboardBottomInset: CGFloat = 0
  private var originalScrollInsets: (content: UIEdgeInsets, indicator: UIEdgeInsets)?
  private var didDeferPresentationForSourceView: Bool = false

  private struct ResolvedAnchorLayout {
    var targetFrame: CGRect
    var maskCoverageRect: CGRect
    var anchorLineY: CGFloat
    var direction: FKAnchor.Direction
  }

  init(
    owner: FKPresentationController,
    contentController: UIViewController,
    configuration: FKPresentationConfiguration,
    anchorConfiguration: FKAnchorConfiguration
  ) {
    self.owner = owner
    self.contentController = contentController
    self.configuration = configuration
    self.anchorConfiguration = anchorConfiguration
    super.init()
  }

  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    guard !isPresented else { completion?(); return }
    self.presentingViewController = presentingViewController

    // If the source view hasn't been attached to a window yet, resolving its geometry is unreliable.
    // We defer once to the next runloop turn to allow UIKit to finish view attachment/layout.
    if shouldDeferPresentationBecauseSourceViewIsNotInWindow(), !didDeferPresentationForSourceView {
      didDeferPresentationForSourceView = true
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.present(from: presentingViewController, animated: animated, completion: completion)
      }
      return
    }

    resolveHostAndParent(for: anchorConfiguration, fallbackParent: presentingViewController)
    guard let hostView, let parentViewController else { completion?(); return }

    let hostVC = ensureAnchorHostViewController(parent: parentViewController, hostView: hostView)
    embedContent(into: hostVC)

    updateLayout(animated: false, duration: 0, options: .curveLinear)
    applyZOrderPolicy()

    isPresented = true

    let animator = makeAnimator(isPresentation: true, animated: animated)
    animator.addCompletion { [weak self] _ in
      guard let self else { return }
      completion?()
    }
    animator.startAnimation()

    startRepositionObservation(in: hostView)
    startKeyboardTrackingIfNeeded()
  }

  func dismiss(animated: Bool, completion: (() -> Void)?) {
    guard isPresented else { completion?(); return }
    isPresented = false
    stopRepositionObservation()
    stopKeyboardTracking()

    let animator = makeAnimator(isPresentation: false, animated: animated)
    animator.addCompletion { [weak self] _ in
      guard let self else { return }
      self.cleanup()
      completion?()
    }
    animator.startAnimation()
  }
  
  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    guard let hostView, let hostVC = anchorHostViewController else { return }

    let resolved = resolveLayout(in: hostView)
    let applyLayout = {
      hostVC.applyLayout(.init(
        hostBounds: hostView.bounds,
        presentationFrame: resolved.targetFrame,
        maskCoverageRect: resolved.maskCoverageRect,
        anchorLineY: resolved.anchorLineY,
        direction: resolved.direction
      ))
      hostVC.contentContainerView.layoutIfNeeded()
    }

    guard animated else {
      applyLayout()
      applyZOrderPolicy()
      return
    }

    let animations = {
      applyLayout()
    }
    UIView.animate(
      withDuration: max(0, duration),
      delay: 0,
      options: [options, .beginFromCurrentState, .allowUserInteraction],
      animations: animations
    ) { _ in
      self.applyZOrderPolicy()
    }
  }

  // MARK: - Host resolution

  private func resolveHostAndParent(for anchorConfiguration: FKAnchorConfiguration, fallbackParent: UIViewController) {
    switch anchorConfiguration.hostStrategy {
    case .inSameSuperviewBelowAnchor:
      guard case let .view(box) = anchorConfiguration.anchor.source, let sourceView = box.object else { return }
      self.sourceView = sourceView
      let host = findHostView(for: sourceView)
      hostView = host
      directAnchorChild = findDirectChild(of: host, containing: sourceView)
      if host.fk_firstViewController == nil {
        // We still allow presentation in Release by falling back to the caller-provided parent.
        // This keeps the anchor-host path safe and avoids crashes even in unusual view hierarchies.
        assertionFailure("FKAnchorHost: Failed to resolve parentViewController from hostView responder chain. Falling back to the presenting view controller as containment parent.")
      }
      parentViewController = host.fk_firstViewController ?? fallbackParent
    case let .inProvidedContainer(box):
      hostView = box.object
      if case let .view(anchorBox) = anchorConfiguration.anchor.source {
        sourceView = anchorBox.object
      } else {
        sourceView = nil
      }
      if let hostView, let sourceView {
        directAnchorChild = findDirectChild(of: hostView, containing: sourceView)
      } else {
        directAnchorChild = nil
      }
      if hostView?.fk_firstViewController == nil {
        assertionFailure("FKAnchorHost: Provided host container does not have a parent view controller in responder chain. Falling back to the presenting view controller as containment parent.")
      }
      parentViewController = hostView?.fk_firstViewController ?? fallbackParent
    case .inWindowLevel:
      let win = presentingViewController?.view.window ?? UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first
      hostView = win
      if let win, let sourceView {
        directAnchorChild = findDirectChild(of: win, containing: sourceView)
      } else {
        directAnchorChild = nil
      }
      parentViewController = win?.rootViewController ?? fallbackParent
    }
  }

  private func findHostView(for sourceView: UIView) -> UIView {
    // Prefer the source's immediate superview as hosting container.
    if let superview = sourceView.superview {
      return superview
    }
    if let window = sourceView.window {
      return window
    }
    if let vc = sourceView.fk_firstViewController {
      return vc.view
    }
    return sourceView
  }

  private func findDirectChild(of host: UIView, containing view: UIView) -> UIView? {
    var node: UIView? = view
    while let current = node, current.superview != nil, current.superview !== host {
      node = current.superview
    }
    return node
  }

  private func applyZOrderPolicy() {
    guard anchorConfiguration.zOrderPolicy == .keepAnchorAbovePresentation else { return }
    guard let hostView else { return }
    // Re-apply on every layout/reposition pass because host subview order may be mutated externally
    // (e.g. other features inserting overlays). Without this, anchor-attached visuals regress quickly.
    if let sourceView, sourceView.superview === hostView {
      hostView.bringSubviewToFront(sourceView)
      return
    }
    if let directAnchorChild {
      hostView.bringSubviewToFront(directAnchorChild)
    }
  }

  // MARK: - Containment

  private func ensureAnchorHostViewController(parent: UIViewController, hostView: UIView) -> FKAnchorHostViewController {
    if let existing = anchorHostViewController, existing.parent === parent {
      return existing
    }

    let vc = FKAnchorHostViewController(configuration: configuration)
    vc.onRequestDismiss = { [weak self] in
      // Route dismiss through owner to keep lifecycle callbacks/state in sync.
      self?.owner.dismiss(animated: true, completion: nil)
    }
    vc.onProgress = { [weak self] progress in
      self?.owner.notifyProgress(progress)
    }

    parent.addChild(vc)

    // Presentation layer is added to host, then anchor/direct-child is brought to front.
    hostView.addSubview(vc.view)
    vc.view.frame = hostView.bounds
    vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    vc.didMove(toParent: parent)

    anchorHostViewController = vc
    return vc
  }

  private func embedContent(into anchorHostViewController: FKAnchorHostViewController) {
    if contentController.parent === anchorHostViewController {
      return
    }

    anchorHostViewController.addChild(contentController)
    contentController.view.translatesAutoresizingMaskIntoConstraints = false
    anchorHostViewController.contentContainerView.addSubview(contentController.view)
    NSLayoutConstraint.activate([
      contentController.view.leadingAnchor.constraint(equalTo: anchorHostViewController.contentContainerView.leadingAnchor),
      contentController.view.trailingAnchor.constraint(equalTo: anchorHostViewController.contentContainerView.trailingAnchor),
      contentController.view.topAnchor.constraint(equalTo: anchorHostViewController.contentContainerView.topAnchor),
      contentController.view.bottomAnchor.constraint(equalTo: anchorHostViewController.contentContainerView.bottomAnchor),
    ])
    contentController.didMove(toParent: anchorHostViewController)
  }

  private func cleanup() {
    stopRepositionObservation()

    if let hostVC = anchorHostViewController {
      if contentController.parent === hostVC {
        contentController.willMove(toParent: nil)
        contentController.view.removeFromSuperview()
        contentController.removeFromParent()
      }
      hostVC.willMove(toParent: nil)
      hostVC.view.removeFromSuperview()
      hostVC.removeFromParent()
    }

    anchorHostViewController = nil
    parentViewController = nil
    hostView = nil
    directAnchorChild = nil
    sourceView = nil
  }

  // MARK: - Layout

  private func resolveLayout(in host: UIView) -> ResolvedAnchorLayout {
    let bounds = host.bounds
    let safeInsets = containerSafeInsets(in: host)

    let result = FKPresentationAnchorLayout.anchoredFrame(
      in: host,
      bounds: bounds,
      safeInsets: safeInsets,
      anchor: anchorConfiguration.anchor,
      measuredContentHeight: { [weak self] in
        guard let self else { return 320 }
        let preferred = self.contentController.preferredContentSize.height
        return preferred > 0 ? preferred : 320
      }
    )

    var frame = result.frame
    // Keyboard avoidance runs after anchor geometry is resolved so we keep attachment semantics first,
    // then apply compatibility offsets for active input contexts.
    frame = applyKeyboardAvoidance(to: frame, in: host)

    let sourceRect = result.sourceRect ?? .zero
    let attachmentY: CGFloat = (anchorConfiguration.anchor.edge == .top) ? sourceRect.minY : sourceRect.maxY
    let anchorLineY: CGFloat = {
      switch result.resolvedDirection {
      case .down:
        return attachmentY + anchorConfiguration.anchor.offset
      case .up:
        return attachmentY - anchorConfiguration.anchor.offset
      case .auto:
        return attachmentY + anchorConfiguration.anchor.offset
      }
    }()

    let maskCoverageRect: CGRect = {
      switch anchorConfiguration.maskCoveragePolicy {
      case .fullScreen:
        return host.bounds
      case .belowAnchorOnly:
        // Keep interaction mask local to the anchor side so controls above the anchor remain interactive.
        // This keeps anchor-dropdown interaction localized instead of modal full-screen capture.
        let top = sourceRect.maxY
        return CGRect(x: host.bounds.minX, y: top, width: host.bounds.width, height: max(0, host.bounds.maxY - top))
      }
    }()

    return .init(
      targetFrame: frame,
      maskCoverageRect: maskCoverageRect,
      anchorLineY: anchorLineY,
      direction: result.resolvedDirection
    )
  }

  private func containerSafeInsets(in host: UIView) -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea:
      return .zero
    case .containerRespectsSafeArea:
      return host.safeAreaInsets
    }
  }

  // MARK: - Animation

  private func makeAnimator(isPresentation: Bool, animated: Bool) -> UIViewPropertyAnimator {
    let reduceMotion = UIAccessibility.isReduceMotionEnabled
    guard let hostVC = anchorHostViewController else {
      return UIViewPropertyAnimator(duration: 0, curve: .linear) {}
    }
    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      layout: .anchor(anchorConfiguration),
      animationConfiguration: configuration.animation,
      isPresentation: isPresentation,
      reduceMotionEnabled: reduceMotion,
      interactionState: .nonInteractive
    )

    let duration = animated ? style.duration : 0
    let animations: () -> Void = { [weak self] in
      guard let self, let hostView = self.hostView else { return }
      let resolved = self.resolveLayout(in: hostView)
      if isPresentation {
        hostVC.animateMaskAlpha(1)
        hostVC.wrapperView.frame = resolved.targetFrame
      } else {
        hostVC.animateMaskAlpha(0)
        hostVC.wrapperView.frame = self.offsetFrameByHeight(from: hostVC.currentPresentationFrame, direction: resolved.direction)
      }
      hostVC.applyLayout(.init(
        hostBounds: hostView.bounds,
        presentationFrame: hostVC.wrapperView.frame,
        maskCoverageRect: resolved.maskCoverageRect,
        anchorLineY: resolved.anchorLineY,
        direction: resolved.direction
      ))
    }

    if duration == 0 {
      // `UIViewPropertyAnimator(duration:animations:)` already captures the animation block,
      // so adding the same block again would run layout updates twice.
      return UIViewPropertyAnimator(duration: 0, curve: .linear, animations: animations)
    }

    let animator: UIViewPropertyAnimator = {
      switch style.timing {
      case let .spring(dampingRatio):
        let params = UISpringTimingParameters(dampingRatio: dampingRatio, initialVelocity: .zero)
        return UIViewPropertyAnimator(duration: duration, timingParameters: params)
      case let .curve(curve):
        return UIViewPropertyAnimator(duration: duration, curve: curve)
      }
    }()

    if isPresentation {
      if let hostView = hostView {
        let resolved = resolveLayout(in: hostView)
        hostVC.wrapperView.frame = offsetFrameByHeight(from: resolved.targetFrame, direction: resolved.direction)
        hostVC.applyLayout(.init(
          hostBounds: hostView.bounds,
          presentationFrame: hostVC.wrapperView.frame,
          maskCoverageRect: resolved.maskCoverageRect,
          anchorLineY: resolved.anchorLineY,
          direction: resolved.direction
        ))
      }
      hostVC.wrapperView.alpha = 1
      hostVC.animateMaskAlpha(0)
    }
    animator.addAnimations(animations)
    return animator
  }

  private func offsetFrameByHeight(from baseFrame: CGRect, direction: FKAnchor.Direction) -> CGRect {
    let offsetY: CGFloat
    switch direction {
    case .down:
      // Downward-attached panel enters from above and exits upward.
      offsetY = -baseFrame.height
    case .up:
      // Upward-attached panel enters from below and exits downward.
      offsetY = baseFrame.height
    case .auto:
      // Auto should already be resolved, but keep a safe fallback.
      offsetY = -baseFrame.height
    }
    return baseFrame.offsetBy(dx: 0, dy: offsetY)
  }

  // MARK: - Gestures
  // Gestures are owned by FKAnchorHostViewController.

  // MARK: - Reposition observation

  private func startRepositionObservation(in host: UIView) {
    let policy = anchorConfiguration.repositionPolicy
    repositionCoordinator.startObserving(
      in: host,
      listenLayoutChanges: policy.listensToLayoutChanges,
      listenTraitChanges: policy.listensToTraitChanges,
      debounceInterval: policy.debounceInterval
    ) { [weak self] in
      guard let self else { return }
      self.refreshAnchorHierarchy()
      self.updateLayout(animated: false, duration: 0, options: .curveLinear)
    }

    if policy.listensToOrientationChanges {
      orientationObserver = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.refreshAnchorHierarchy()
        self?.updateLayout(animated: false, duration: 0, options: .curveLinear)
      }
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
  }

  private func stopRepositionObservation() {
    repositionCoordinator.stopObserving()
    if let orientationObserver {
      NotificationCenter.default.removeObserver(orientationObserver)
      self.orientationObserver = nil
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
  }

  private func refreshAnchorHierarchy() {
    guard let hostView else { return }
    guard case .inSameSuperviewBelowAnchor = anchorConfiguration.hostStrategy else { return }
    guard let sourceView else { return }
    guard sourceView.window != nil else { return }

    let activeHost: UIView
    switch anchorConfiguration.hostStrategy {
    case .inSameSuperviewBelowAnchor:
      let newHost = findHostView(for: sourceView)
      if newHost !== hostView {
        // The source view moved to another host container. Rebind our host and restart observation.
        self.hostView = newHost
        stopRepositionObservation()
        startRepositionObservation(in: newHost)
      }
      activeHost = self.hostView ?? newHost
    case .inProvidedContainer:
      activeHost = hostView
    case .inWindowLevel:
      activeHost = hostView
    }

    // The direct child relationship can change after layout updates, so resolve it every cycle before z-order.
    directAnchorChild = findDirectChild(of: activeHost, containing: sourceView)
    if let hostVC = anchorHostViewController, hostVC.view.superview !== activeHost {
      activeHost.addSubview(hostVC.view)
      hostVC.view.frame = activeHost.bounds
      hostVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    applyZOrderPolicy()
  }

  private func shouldDeferPresentationBecauseSourceViewIsNotInWindow() -> Bool {
    guard case .inSameSuperviewBelowAnchor = anchorConfiguration.hostStrategy else { return false }
    guard case let .view(box) = anchorConfiguration.anchor.source, let sourceView = box.object else { return false }
    return sourceView.window == nil
  }

  // MARK: - Keyboard avoidance (anchor)

  private func startKeyboardTrackingIfNeeded() {
    guard configuration.keyboardAvoidance.isEnabled else { return }
    guard keyboardObservers.isEmpty else { return }

    let center = NotificationCenter.default
    let handler: (Notification) -> Void = { [weak self] note in
      guard let self else { return }
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      self.handleKeyboard(endFrameScreen: endFrameScreen, duration: duration, curveRaw: curveRaw)
    }

    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main,
      using: handler
    ))
    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main,
      using: handler
    ))
  }

  private func stopKeyboardTracking() {
    let center = NotificationCenter.default
    keyboardObservers.forEach { center.removeObserver($0) }
    keyboardObservers.removeAll()
    keyboardBottomInset = 0

    if let scroll = findPrimaryScrollView(in: contentController.view), let originalScrollInsets {
      scroll.contentInset = originalScrollInsets.content
      scroll.scrollIndicatorInsets = originalScrollInsets.indicator
    }
    originalScrollInsets = nil
  }

  private func handleKeyboard(endFrameScreen: CGRect, duration: Double, curveRaw: Int) {
    guard let hostView else { return }
    guard configuration.keyboardAvoidance.isEnabled else { return }

    let endFrameInWindow = hostView.window?.convert(endFrameScreen, from: nil) ?? endFrameScreen
    let endFrame = hostView.convert(endFrameInWindow, from: hostView.window)
    let intersection = hostView.bounds.intersection(endFrame)
    let keyboardHeight = intersection.isNull ? 0 : intersection.height
    let safeBottom = hostView.safeAreaInsets.bottom
    let additional = configuration.keyboardAvoidance.additionalBottomInset
    let targetInset = max(0, keyboardHeight - safeBottom + additional)
    keyboardBottomInset = targetInset

    let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
    UIView.animate(withDuration: duration, delay: 0, options: [options, .allowUserInteraction]) {
      self.updateLayout(animated: false, duration: 0, options: .curveLinear)
    }
  }

  private func applyKeyboardAvoidance(to frame: CGRect, in hostView: UIView) -> CGRect {
    guard configuration.keyboardAvoidance.isEnabled else { return frame }
    let strategy = configuration.keyboardAvoidance.strategy

    if keyboardBottomInset <= 0 {
      return frame
    }

    switch strategy {
    case .disabled:
      return frame
    case .adjustContainer, .interactive:
      let keyboardTopY = hostView.bounds.height - keyboardBottomInset
      let overlap = max(0, frame.maxY - keyboardTopY)
      return frame.offsetBy(dx: 0, dy: -overlap)
    case .adjustContentInsets:
      guard let scroll = findPrimaryScrollView(in: contentController.view) else { return frame }
      if originalScrollInsets == nil {
        originalScrollInsets = (scroll.contentInset, scroll.scrollIndicatorInsets)
      }
      let base = originalScrollInsets ?? (scroll.contentInset, scroll.scrollIndicatorInsets)
      scroll.contentInset = .init(
        top: base.content.top,
        left: base.content.left,
        bottom: base.content.bottom + keyboardBottomInset,
        right: base.content.right
      )
      scroll.scrollIndicatorInsets = .init(
        top: base.indicator.top,
        left: base.indicator.left,
        bottom: base.indicator.bottom + keyboardBottomInset,
        right: base.indicator.right
      )
      return frame
    }
  }

  private func findPrimaryScrollView(in root: UIView?) -> UIScrollView? {
    guard let root else { return nil }
    if let scroll = root as? UIScrollView { return scroll }
    for sub in root.subviews {
      if let found = findPrimaryScrollView(in: sub) { return found }
    }
    return nil
  }
}

