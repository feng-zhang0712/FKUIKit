import UIKit

@MainActor
final class FKEmbeddedAnchorHost: NSObject, FKPresentationHosting {
  /*
   Regression notes (legacy FKPresentation as gold standard)
   --------------------------------------------------------
   Current embedded path must match the old UIView-based FKPresentation behavior:
   - Host container: legacy hosts inside the anchor's resolved container (not window-level by default).
   - Insertion: legacy inserts presentation above other subviews and inserts mask below it; then brings
     the anchor (or its direct host child) to front on every reposition.
   - Geometry: the presentation edge is attached to the anchor edge with zero vertical spacing by default.
   - Mask coverage: legacy default covers only the region *below sourceView* (not full screen).
   - Animation: legacy is edge-attached (sheet-like), not alert-like scaling.
   - Corners/shadow: legacy defaults to rounding only the free edge corners and follows the free-edge shadow.
   */
  private unowned let owner: FKPresentationController
  private let contentController: UIViewController
  private let configuration: FKPresentationConfiguration
  private let embeddedConfiguration: FKEmbeddedAnchorConfiguration

  private(set) var isPresented: Bool = false

  private weak var presentingViewController: UIViewController?
  private weak var parentViewController: UIViewController?
  private weak var hostView: UIView?
  private weak var directAnchorChild: UIView?
  private weak var sourceView: UIView?

  private var embeddedHostViewController: FKEmbeddedHostViewController?

  private let repositionCoordinator = FKEmbeddedRepositionCoordinator()
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
    embeddedConfiguration: FKEmbeddedAnchorConfiguration
  ) {
    self.owner = owner
    self.contentController = contentController
    self.configuration = configuration
    self.embeddedConfiguration = embeddedConfiguration
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

    resolveHostAndParent(for: embeddedConfiguration, fallbackParent: presentingViewController)
    guard let hostView, let parentViewController else { completion?(); return }

    let hostVC = ensureEmbeddedHostViewController(parent: parentViewController, hostView: hostView)
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
    guard let hostView, let hostVC = embeddedHostViewController else { return }

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

  private func resolveHostAndParent(for embeddedConfiguration: FKEmbeddedAnchorConfiguration, fallbackParent: UIViewController) {
    if case let .view(box) = embeddedConfiguration.anchor.source {
      self.sourceView = box.object
    } else {
      self.sourceView = nil
    }

    switch embeddedConfiguration.hostStrategy {
    case .inSameSuperviewBelowAnchor:
      guard let sourceView else { return }
      let host = findHostView(for: sourceView)
      hostView = host
      directAnchorChild = findDirectChild(of: host, containing: sourceView)
      if host.firstViewController == nil {
        // We still allow presentation in Release by falling back to the caller-provided parent.
        // This keeps the embedded path safe and avoids crashes even in unusual view hierarchies.
        assertionFailure("FKEmbeddedAnchorHost: Failed to resolve parentViewController from hostView responder chain. Falling back to the presenting view controller as containment parent.")
      }
      parentViewController = host.firstViewController ?? fallbackParent
    case let .inProvidedContainer(box):
      hostView = box.object
      if let hostView, let sourceView {
        directAnchorChild = findDirectChild(of: hostView, containing: sourceView)
      } else {
        directAnchorChild = nil
      }
      if hostView?.firstViewController == nil {
        assertionFailure("FKEmbeddedAnchorHost: Provided host container does not have a parent view controller in responder chain. Falling back to the presenting view controller as containment parent.")
      }
      parentViewController = hostView?.firstViewController ?? fallbackParent
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
    // Match legacy FKPresentation behavior:
    // prefer the source's immediate superview as hosting container.
    if let superview = sourceView.superview {
      return superview
    }
    if let window = sourceView.window {
      return window
    }
    if let vc = sourceView.firstViewController {
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
    guard embeddedConfiguration.zOrderPolicy == .keepAnchorAbovePresentation else { return }
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

  private func ensureEmbeddedHostViewController(parent: UIViewController, hostView: UIView) -> FKEmbeddedHostViewController {
    if let existing = embeddedHostViewController, existing.parent === parent {
      return existing
    }

    let vc = FKEmbeddedHostViewController(configuration: configuration)
    vc.onRequestDismiss = { [weak self] in
      // Route dismiss through owner to keep lifecycle callbacks/state in sync.
      self?.owner.dismiss(animated: true, completion: nil)
    }
    vc.onProgress = { [weak self] progress in
      self?.owner.notifyProgress(progress)
    }

    parent.addChild(vc)

    // Legacy semantics: presentation layer is added to host, then anchor/direct-child is brought to front.
    hostView.addSubview(vc.view)
    vc.view.frame = hostView.bounds
    vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    vc.didMove(toParent: parent)

    embeddedHostViewController = vc
    return vc
  }

  private func embedContent(into embeddedHostViewController: FKEmbeddedHostViewController) {
    if contentController.parent === embeddedHostViewController {
      return
    }

    embeddedHostViewController.addChild(contentController)
    contentController.view.translatesAutoresizingMaskIntoConstraints = false
    embeddedHostViewController.contentContainerView.addSubview(contentController.view)
    NSLayoutConstraint.activate([
      contentController.view.leadingAnchor.constraint(equalTo: embeddedHostViewController.contentContainerView.leadingAnchor),
      contentController.view.trailingAnchor.constraint(equalTo: embeddedHostViewController.contentContainerView.trailingAnchor),
      contentController.view.topAnchor.constraint(equalTo: embeddedHostViewController.contentContainerView.topAnchor),
      contentController.view.bottomAnchor.constraint(equalTo: embeddedHostViewController.contentContainerView.bottomAnchor),
    ])
    contentController.didMove(toParent: embeddedHostViewController)
  }

  private func cleanup() {
    stopRepositionObservation()

    if let hostVC = embeddedHostViewController {
      if contentController.parent === hostVC {
        contentController.willMove(toParent: nil)
        contentController.view.removeFromSuperview()
        contentController.removeFromParent()
      }
      hostVC.willMove(toParent: nil)
      hostVC.view.removeFromSuperview()
      hostVC.removeFromParent()
    }

    embeddedHostViewController = nil
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
      anchor: embeddedConfiguration.anchor,
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
    let attachmentY: CGFloat = (embeddedConfiguration.anchor.edge == .top) ? sourceRect.minY : sourceRect.maxY
    let anchorLineY: CGFloat = {
      switch result.resolvedDirection {
      case .down:
        return attachmentY + embeddedConfiguration.anchor.offset
      case .up:
        return attachmentY - embeddedConfiguration.anchor.offset
      case .auto:
        return attachmentY + embeddedConfiguration.anchor.offset
      }
    }()

    let maskCoverageRect: CGRect = {
      switch embeddedConfiguration.maskCoveragePolicy {
      case .fullScreen:
        return host.bounds
      case .belowAnchorOnly:
        // Keep interaction mask local to the anchor side so controls above the anchor remain interactive.
        // This intentionally preserves legacy embedded-dropdown behavior instead of modal full-screen capture.
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
    guard let hostVC = embeddedHostViewController else {
      return UIViewPropertyAnimator(duration: 0, curve: .linear) {}
    }
    let style = FKAnimationStyleResolver.resolveTransitionStyle(
      mode: .anchor(embeddedConfiguration.anchor),
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
  // Gestures are owned by FKEmbeddedHostViewController.

  // MARK: - Reposition observation

  private func startRepositionObservation(in host: UIView) {
    let policy = embeddedConfiguration.repositionPolicy
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
    guard let sourceView else { return }
    guard sourceView.window != nil else { return }

    let activeHost: UIView
    switch embeddedConfiguration.hostStrategy {
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
    if let hostVC = embeddedHostViewController, hostVC.view.superview !== activeHost {
      activeHost.addSubview(hostVC.view)
      hostVC.view.frame = activeHost.bounds
      hostVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    applyZOrderPolicy()
  }

  private func shouldDeferPresentationBecauseSourceViewIsNotInWindow() -> Bool {
    guard case .inSameSuperviewBelowAnchor = embeddedConfiguration.hostStrategy else { return false }
    guard case let .view(box) = embeddedConfiguration.anchor.source, let sourceView = box.object else { return false }
    return sourceView.window == nil
  }

  // MARK: - Keyboard avoidance (embedded)

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

private extension UIView {
  var firstViewController: UIViewController? {
    var responder: UIResponder? = self
    while let r = responder {
      if let vc = r as? UIViewController { return vc }
      responder = r.next
    }
    return nil
  }
}

@MainActor
private final class FKEmbeddedRepositionCoordinator {
  private weak var probeView: FKEmbeddedRepositionProbeView?
  private var isScheduled = false
  private var onReposition: (() -> Void)?
  private var debounceInterval: TimeInterval = 0
  private var pendingWorkItem: DispatchWorkItem?

  func startObserving(
    in host: UIView,
    listenLayoutChanges: Bool,
    listenTraitChanges: Bool,
    debounceInterval: TimeInterval,
    onRepositionRequested: @escaping () -> Void
  ) {
    self.onReposition = onRepositionRequested
    self.debounceInterval = max(0, debounceInterval)

    let probe: FKEmbeddedRepositionProbeView
    if let existing = probeView, existing.superview === host {
      probe = existing
    } else {
      probeView?.removeFromSuperview()
      let newProbe = FKEmbeddedRepositionProbeView(frame: host.bounds)
      newProbe.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      newProbe.isUserInteractionEnabled = false
      host.addSubview(newProbe)
      host.sendSubviewToBack(newProbe)
      probeView = newProbe
      probe = newProbe
    }

    probe.onHostChange = { [weak self] didLayoutChange, didTraitChange in
      guard let self else { return }
      if didLayoutChange, !listenLayoutChanges { return }
      if didTraitChange, !listenTraitChanges { return }
      self.schedule()
    }
  }

  func stopObserving() {
    pendingWorkItem?.cancel()
    pendingWorkItem = nil
    probeView?.removeFromSuperview()
    probeView = nil
    isScheduled = false
    onReposition = nil
  }

  private func schedule() {
    if debounceInterval > 0 {
      pendingWorkItem?.cancel()
      let item = DispatchWorkItem { [weak self] in
        self?.onReposition?()
      }
      pendingWorkItem = item
      DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: item)
      return
    }

    guard !isScheduled else { return }
    isScheduled = true
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.isScheduled = false
      self.onReposition?()
    }
  }
}

private final class FKEmbeddedRepositionProbeView: UIView {
  var onHostChange: ((_ didLayoutChange: Bool, _ didTraitChange: Bool) -> Void)?
  private var lastBoundsSize: CGSize = .zero

  override init(frame: CGRect) {
    super.init(frame: frame)
    isHidden = true
    lastBoundsSize = bounds.size
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    let didLayoutChange = bounds.size != lastBoundsSize
    lastBoundsSize = bounds.size
    guard didLayoutChange else { return }
    onHostChange?(true, false)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard let previousTraitCollection else { return }
    let didTraitChange =
      previousTraitCollection.horizontalSizeClass != traitCollection.horizontalSizeClass ||
      previousTraitCollection.verticalSizeClass != traitCollection.verticalSizeClass ||
      previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle ||
      previousTraitCollection.displayScale != traitCollection.displayScale
    guard didTraitChange else { return }
    onHostChange?(false, true)
  }
}

