import UIKit

/// Container presentation controller responsible for frame calculation and backdrop wiring.
@MainActor
final class FKContainerPresentationController: UIPresentationController {
  private weak var owner: FKPresentationController?
  private let configuration: FKPresentationConfiguration
  private let interactionController: FKPresentationDismissInteractionController
  private let backdropView = FKPresentationBackdropView()
  private let chromeView = UIView()
  private let wrapperView = UIView()
  private let contentContainerView = UIView()
  private let grabberView = UIView()
  private weak var embeddedPresentedView: UIView?

  private lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  private lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  private var resolvedDetentHeights: [CGFloat] = []
  private var currentDetentIndex: Int = 0
  private var panStartFrame: CGRect = .zero
  private var isPanningSheet: Bool = false
  private var isInteractiveDismissing = false
  private var dismissPanStartTranslationY: CGFloat = 0

  private var keyboardBottomInset: CGFloat = 0
  private var keyboardObservers: [NSObjectProtocol] = []
  private var originalScrollInsets: (content: UIEdgeInsets, indicator: UIEdgeInsets)?
  private weak var presentingEffectHostView: UIView?
  private var presentingBlurView: UIVisualEffectView?

  /// Creates a container presentation controller with configuration and interaction dependencies.
  init(
    presentedViewController: UIViewController,
    presenting presentingViewController: UIViewController?,
    owner: FKPresentationController?,
    configuration: FKPresentationConfiguration,
    interactionController: FKPresentationDismissInteractionController
  ) {
    self.owner = owner
    self.configuration = configuration
    self.interactionController = interactionController
    super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
  }

  /// We wrap the system-provided presented view to enable corner radius, shadow, transforms, and chrome.
  public override var presentedView: UIView? {
    wrapperView
  }

  public override var frameOfPresentedViewInContainerView: CGRect {
    guard let containerView else { return .zero }
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)

    switch configuration.mode {
    case .bottomSheet:
      let height = resolvedSheetHeight(in: containerView, bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(in: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y = bounds.height - height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0)
      return CGRect(x: x, y: y, width: width, height: height)
    case .topSheet:
      let height = resolvedSheetHeight(in: containerView, bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(in: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y: CGFloat = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      return CGRect(x: x, y: y, width: width, height: height)
    case .center:
      return resolvedCenterFrame(in: containerView, bounds: bounds, safeInsets: safeInsets)
    case let .anchor(anchor):
      return anchoredFrame(in: containerView, bounds: bounds, safeInsets: safeInsets, anchor: anchor)
    case .anchorEmbedded:
      // Embedded anchors are not presented via UIPresentationController.
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

    wrapperView.backgroundColor = .white
    // Content should be below chrome so the grabber is never covered by the presented view.
    wrapperView.addSubview(contentContainerView)
    wrapperView.addSubview(chromeView)
    contentContainerView.backgroundColor = .clear
    contentContainerView.clipsToBounds = true

    if let systemPresentedView = super.presentedViewController.view {
      embeddedPresentedView?.removeFromSuperview()
      embeddedPresentedView = systemPresentedView
      systemPresentedView.removeFromSuperview()
      contentContainerView.addSubview(systemPresentedView)
    }

    currentDetentIndex = configuration.sheet.initialDetentIndex
    recalculateDetentsIfNeeded()
    configureGrabberIfNeeded()
    installGesturesIfNeeded()
    startKeyboardTrackingIfNeeded()

    configureAccessibility()
    applyPresentingViewEffectIfNeeded(isPresenting: true)
    updateBackdropForCurrentState()

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

    wrapperView.frame = frameOfPresentedViewInContainerView
    chromeView.frame = wrapperView.bounds
    layoutContentContainer()
    embeddedPresentedView?.frame = contentContainerView.bounds

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
    } else {
      // Interactive dismiss can cancel after intermediate visual changes; restore backdrop/effect state
      // so the re-presented sheet remains visually consistent and does not look half-dismissed.
      applyPresentingViewEffectIfNeeded(isPresenting: true)
      updateBackdropForCurrentState()
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
      self.embeddedPresentedView?.frame = self.contentContainerView.bounds
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

  private func installGesturesIfNeeded() {
    let allowsPassthrough = configuration.backgroundInteraction.isEnabled
    backdropView.isUserInteractionEnabled = !allowsPassthrough
    if allowsPassthrough, !configuration.backgroundInteraction.showsBackdropWhenEnabled {
      backdropView.isHidden = true
    } else {
      backdropView.isHidden = false
    }

    if !allowsPassthrough, configuration.dismissBehavior.allowsTapOutside, configuration.dismissBehavior.allowsBackdropTap {
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.removeGestureRecognizer(tapToDismissGesture)
    }

    let allowsSwipe: Bool = {
      if case .center = configuration.mode { return configuration.center.dismissEnabled }
      return configuration.dismissBehavior.allowsSwipe
    }()

    if allowsSwipe {
      panToDismissGesture.maximumNumberOfTouches = 1
      wrapperView.addGestureRecognizer(panToDismissGesture)
    } else {
      wrapperView.removeGestureRecognizer(panToDismissGesture)
    }
  }

  private func applyContainerAppearance() {
    // Corner radius and masking should apply to the wrapper so chrome + content clip together.
    wrapperView.layer.cornerRadius = configuration.cornerRadius
    wrapperView.layer.masksToBounds = true

    // Shadow is applied to the presentedView's superlayer in a real implementation.
    // For minimal chain, we apply it to the wrapper's layer and keep it easily replaceable.
    wrapperView.layer.shadowColor = configuration.shadow.color.cgColor
    wrapperView.layer.shadowOpacity = configuration.shadow.opacity
    wrapperView.layer.shadowRadius = configuration.shadow.radius
    wrapperView.layer.shadowOffset = configuration.shadow.offset
    wrapperView.layer.shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: configuration.cornerRadius).cgPath

    if configuration.border.isEnabled {
      wrapperView.layer.borderColor = configuration.border.color.cgColor
      wrapperView.layer.borderWidth = configuration.border.width
    } else {
      wrapperView.layer.borderWidth = 0
    }
  }

  private func containerSafeInsets(in containerView: UIView) -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea:
      return .zero
    case .containerRespectsSafeArea:
      return containerView.safeAreaInsets
    }
  }

  private func layoutContentContainer() {
    guard let containerView else {
      contentContainerView.frame = wrapperView.bounds
      return
    }

    if configuration.safeAreaPolicy == .contentRespectsSafeArea {
      // Important: For edge-attached sheets, only the *edge* that can collide with system UI
      // should apply safe-area padding. Applying the full (top+bottom) safe area to a bottom sheet
      // creates an artificial “handle panel”/gap above content.
      let safe = containerView.safeAreaInsets
      let insets: UIEdgeInsets = {
        switch configuration.mode {
        case .bottomSheet:
          return .init(top: 0, left: 0, bottom: safe.bottom, right: 0)
        case .topSheet:
          return .init(top: safe.top, left: 0, bottom: 0, right: 0)
        case .center:
          return safe
        case .anchor, .anchorEmbedded:
          // Anchors are typically popover-like; keep content away from unsafe regions.
          return safe
        case let .edge(edge):
          if edge.contains(.bottom) { return .init(top: 0, left: 0, bottom: safe.bottom, right: 0) }
          if edge.contains(.top) { return .init(top: safe.top, left: 0, bottom: 0, right: 0) }
          return safe
        }
      }()
      var frame = wrapperView.bounds.inset(by: insets)
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    } else {
      var frame = wrapperView.bounds
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    }

    // Chrome overlays the whole wrapper; grabber lives in chrome.
    layoutGrabber()
  }

  private func grabberContentInsets() -> UIEdgeInsets {
    guard configuration.sheet.showsGrabber else { return .zero }
    let padding = configuration.sheet.grabberTopInset + configuration.sheet.grabberSize.height + 8
    switch configuration.mode {
    case .bottomSheet:
      return .init(top: padding, left: 0, bottom: 0, right: 0)
    case .topSheet:
      return .init(top: 0, left: 0, bottom: padding, right: 0)
    default:
      return .zero
    }
  }

  private func startKeyboardTrackingIfNeeded() {
    guard configuration.keyboardAvoidance.isEnabled else { return }
    guard keyboardObservers.isEmpty else { return }

    let center = NotificationCenter.default
    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      self?.handleKeyboard(endFrameScreen: endFrameScreen, duration: duration, curveRaw: curveRaw)
    })

    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      self?.handleKeyboard(endFrameScreen: endFrameScreen, duration: duration, curveRaw: curveRaw)
    })
  }

  private func stopKeyboardTracking() {
    let center = NotificationCenter.default
    for token in keyboardObservers {
      center.removeObserver(token)
    }
    keyboardObservers.removeAll()

    // Restore scroll insets if we changed them.
    if let scroll = findPrimaryScrollView(in: presentedViewController.view), let originalScrollInsets {
      scroll.contentInset = originalScrollInsets.content
      scroll.scrollIndicatorInsets = originalScrollInsets.indicator
    }
    originalScrollInsets = nil
    keyboardBottomInset = 0
    wrapperView.transform = .identity
  }

  @MainActor
  private func handleKeyboard(endFrameScreen: CGRect, duration: Double, curveRaw: Int) {
    guard let containerView else { return }
    guard configuration.keyboardAvoidance.isEnabled else { return }

    let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))

    // Convert to container coordinates.
    let endFrameInWindow = containerView.window?.convert(endFrameScreen, from: nil) ?? endFrameScreen
    let endFrame = containerView.convert(endFrameInWindow, from: containerView.window)

    let intersection = containerView.bounds.intersection(endFrame)
    let keyboardHeight = intersection.isNull ? 0 : intersection.height
    let safeBottom = containerView.safeAreaInsets.bottom
    let targetInset = max(0, keyboardHeight - safeBottom + configuration.keyboardAvoidance.additionalBottomInset)
    keyboardBottomInset = targetInset

    let animations: () -> Void = { [weak self] in
      self?.applyKeyboardAvoidance(in: containerView)
    }

    let strategy = configuration.keyboardAvoidance.strategy
    let shouldAnimate = (strategy == .interactive) ? true : duration > 0
    if shouldAnimate {
      UIView.animate(withDuration: duration, delay: 0, options: [options, .allowUserInteraction], animations: animations)
    } else {
      animations()
    }
  }

  private func applyKeyboardAvoidance(in containerView: UIView) {
    guard configuration.keyboardAvoidance.isEnabled else { return }

    switch configuration.keyboardAvoidance.strategy {
    case .disabled:
      return
    case .adjustContentInsets:
      guard let scroll = resolveKeyboardTargetScrollView() else { return }
      if originalScrollInsets == nil {
        originalScrollInsets = (scroll.contentInset, scroll.scrollIndicatorInsets)
      }
      var inset = originalScrollInsets?.content ?? scroll.contentInset
      inset.bottom = (originalScrollInsets?.content.bottom ?? 0) + keyboardBottomInset
      scroll.contentInset = inset
      var indicators = originalScrollInsets?.indicator ?? scroll.scrollIndicatorInsets
      indicators.bottom = (originalScrollInsets?.indicator.bottom ?? 0) + keyboardBottomInset
      scroll.scrollIndicatorInsets = indicators
    case .adjustContainer, .interactive:
      // Re-layout by shrinking available height for bottom/center modes.
      // We do this by temporarily translating the wrapper when it would overlap the keyboard.
      let keyboardTopY = containerView.bounds.height - keyboardBottomInset
      let overlap = max(0, wrapperView.frame.maxY - keyboardTopY)
      wrapperView.transform = CGAffineTransform(translationX: 0, y: -overlap)
    }
  }

  private func configureGrabberIfNeeded() {
    let showsGrabber: Bool
    switch configuration.mode {
    case .bottomSheet, .topSheet:
      showsGrabber = configuration.sheet.showsGrabber
    default:
      showsGrabber = false
    }

    if showsGrabber {
      if grabberView.superview == nil {
        chromeView.addSubview(grabberView)
      }
      grabberView.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
      grabberView.layer.cornerRadius = configuration.sheet.grabberSize.height / 2
      grabberView.isHidden = false
    } else {
      grabberView.isHidden = true
      grabberView.removeFromSuperview()
    }
  }

  private func configureAccessibility() {
    // Backdrop as a dismissible button (when enabled).
    backdropView.isAccessibilityElement = true
    backdropView.accessibilityTraits = [.button]
    backdropView.accessibilityLabel = configuration.accessibility.dismissLabel

    let dismissAction = UIAccessibilityCustomAction(name: configuration.accessibility.dismissActionName) { [weak self] _ in
      guard let self else { return false }
      self.presentedViewController.dismiss(animated: true)
      return true
    }
    backdropView.accessibilityCustomActions = [dismissAction]

    wrapperView.isAccessibilityElement = false

    if grabberView.superview != nil, !grabberView.isHidden {
      grabberView.isAccessibilityElement = true
      grabberView.accessibilityTraits = [.adjustable]
      grabberView.accessibilityLabel = configuration.accessibility.grabberLabel
      grabberView.accessibilityHint = configuration.accessibility.grabberHint
    }
  }

  private func layoutGrabber() {
    guard grabberView.superview != nil, !grabberView.isHidden else { return }
    let size = configuration.sheet.grabberSize
    let y: CGFloat = {
      switch configuration.mode {
      case .topSheet:
        // For top sheets, the grabber visually belongs to the bottom edge (like a tray you can pull).
        return max(0, wrapperView.bounds.height - configuration.sheet.grabberTopInset - size.height)
      default:
        return configuration.sheet.grabberTopInset
      }
    }()
    grabberView.frame = CGRect(
      x: (wrapperView.bounds.width - size.width) / 2,
      y: y,
      width: size.width,
      height: size.height
    )
  }

  private func resolvedSheetHeight(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    recalculateDetentsIfNeeded()
    if resolvedDetentHeights.indices.contains(currentDetentIndex) {
      return clampedContentHeight(resolvedDetentHeights[currentDetentIndex], containerView: containerView)
    }
    return clampedContentHeight(min(bounds.height * 0.5, max(240, measuredFitContentHeight(in: containerView))), containerView: containerView)
  }

  private func recalculateDetentsIfNeeded() {
    guard let containerView else { return }
    let bounds = containerView.bounds
    let availableHeight = bounds.height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? (containerView.safeAreaInsets.top + containerView.safeAreaInsets.bottom) : 0)
    resolvedDetentHeights = configuration.sheet.detents.map { detent in
      resolve(detent: detent, availableHeight: availableHeight, containerView: containerView)
    }
    currentDetentIndex = max(0, min(currentDetentIndex, max(0, resolvedDetentHeights.count - 1)))
  }

  private func resolve(detent: FKPresentationDetent, availableHeight: CGFloat, containerView: UIView) -> CGFloat {
    let value: CGFloat
    switch detent {
    case .fitContent:
      let maxHeight = availableHeight * configuration.sheet.maximumFitContentHeightFraction
      value = min(maxHeight, measuredFitContentHeight(in: containerView))
    case let .fixed(points):
      value = min(availableHeight, max(0, points))
    case let .fraction(fraction):
      value = min(availableHeight, max(0, fraction) * availableHeight)
    case .full:
      value = availableHeight
    }
    return clampedContentHeight(value, containerView: containerView)
  }

  private func measuredFitContentHeight(in containerView: UIView) -> CGFloat {
    // Best-effort measurement: prefer Auto Layout fitting size when possible; fallback to preferredContentSize.
    let targetWidth = containerView.bounds.width
    let preferred = presentedViewController.preferredContentSize.height
    if preferred > 0 { return preferred }

    guard let view = embeddedPresentedView else { return 360 }
    let size = view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return max(180, size.height)
  }

  private func resolvedCenterFrame(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets) -> CGRect {
    let margins = configuration.center.minimumMargins
    let maxWidth = bounds.width - (CGFloat(margins.leading + margins.trailing) + safeInsets.left + safeInsets.right)
    let maxHeight = bounds.height - (CGFloat(margins.top + margins.bottom) + safeInsets.top + safeInsets.bottom)

    let size: CGSize
    switch configuration.center.size {
    case let .fixed(fixed):
      size = .init(width: min(maxWidth, max(0, fixed.width)), height: min(maxHeight, max(0, fixed.height)))
    case let .fitted(maxSize):
      let contentW = max(220, presentedViewController.preferredContentSize.width)
      let contentH = max(220, measuredFitContentHeight(in: containerView))
      size = .init(
        width: min(maxWidth, min(maxSize.width, contentW)),
        height: min(maxHeight, min(maxSize.height, contentH))
      )
    }

    let originX = (bounds.width - size.width) / 2
    let originY = (bounds.height - size.height) / 2
    return CGRect(x: originX, y: originY, width: size.width, height: size.height)
  }

  @objc private func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    presentedViewController.dismiss(animated: true)
  }

  @objc private func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    guard let containerView else { return }

    switch configuration.mode {
    case .bottomSheet, .topSheet:
      handleSheetPan(recognizer, in: containerView)
    case .center:
      handleCenterPan(recognizer, in: containerView)
    default:
      break
    }
  }

  private func handleCenterPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    guard configuration.center.dismissEnabled else { return }
    let translation = recognizer.translation(in: containerView)
    let progress = min(max(abs(translation.y) / max(1, containerView.bounds.height * 0.4), 0), 1)
    notifyProgress(progress)
    let velocityY = abs(recognizer.velocity(in: containerView).y)

    if recognizer.state == .ended || recognizer.state == .cancelled {
      if progress > configuration.center.dismissProgressThreshold || velocityY > configuration.center.dismissVelocityThreshold {
        presentedViewController.dismiss(animated: true)
      } else {
        notifyProgress(0)
      }
    }
  }

  private func handleSheetPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: containerView)
    let velocity = recognizer.velocity(in: containerView)

    let trackedScrollView = resolvedTrackedScrollView()

    // Scroll tracking handoff: only begin sheet drag when content can no longer scroll in that direction.
    if recognizer.state == .began {
      if let scroll = trackedScrollView {
        let translationY = recognizer.translation(in: containerView).y
        if !shouldTransferPanFromScrollView(scroll, translationY: translationY) {
          isPanningSheet = false
          return
        }
      }
      isPanningSheet = true
      isInteractiveDismissing = false
      panStartFrame = wrapperView.frame
      dismissPanStartTranslationY = translation.y
    }

    guard isPanningSheet else { return }

    switch recognizer.state {
    case .began, .changed:
      if isInteractiveDismissing {
        let progress = interactiveDismissProgress(translationY: translation.y - dismissPanStartTranslationY, in: containerView)
        interactionController.updateDismissal(progress: progress)
        notifyProgress(progress)
        return
      }

      var frame = panStartFrame
      switch configuration.mode {
      case .bottomSheet:
        // Within detent range, change *height* and keep bottom edge anchored.
        // Only after reaching the lowest detent do we allow a downward translation (dismiss feel).
        let safeInsets = containerSafeInsets(in: containerView)
        let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
        let bottomY = containerView.bounds.height - bottomExtra

        let minHeight = resolvedDetentHeights.min() ?? 240
        let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9

        if currentDetentIndex == 0, translation.y > 0 {
          // At the lowest detent: pull down as translation (pre-dismiss).
          frame.origin.y = panStartFrame.origin.y + translation.y
          frame.size.height = panStartFrame.size.height
        } else {
          // Drag up/down between detents: resize height.
          frame.size.height = panStartFrame.size.height - translation.y
          frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
          frame.origin.y = bottomY - frame.size.height
        }
      case .topSheet:
        // Top sheet is top-anchored: change height.
        frame.size.height = max(0, panStartFrame.height - translation.y)
      default:
        break
      }

      let minY = sheetMinY(in: containerView)
      let maxY = sheetMaxY(in: containerView)
      switch configuration.mode {
      case .bottomSheet:
        // Clamp translation only. When resizing, origin is derived from height; this mainly clamps the pull-down range.
        frame.origin.y = min(max(frame.origin.y, minY - configuration.sheet.dismissThreshold), maxY + configuration.sheet.dismissThreshold)
      case .topSheet:
        // Clamp height by detent range (+ dismiss threshold).
        let minHeight = resolvedDetentHeights.min() ?? 240
        let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9
        frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
        frame.origin.y = minY
      default:
        break
      }

      wrapperView.frame = frame
      chromeView.frame = wrapperView.bounds
      layoutContentContainer()
      embeddedPresentedView?.frame = contentContainerView.bounds
      applyContainerAppearance()

      let progress = sheetDismissProgress(in: containerView)
      notifyProgress(progress)
      updateBackdropForCurrentState()

      // Enter interactive dismissal when user drags beyond threshold from terminal detent.
      if shouldEnterInteractiveDismiss(translationY: translation.y, velocityY: velocity.y) {
        isInteractiveDismissing = true
        dismissPanStartTranslationY = translation.y
        interactionController.beginDismissal(from: presentedViewController)
      }
    case .ended, .cancelled:
      isPanningSheet = false

      if isInteractiveDismissing {
        let progress = interactiveDismissProgress(translationY: translation.y - dismissPanStartTranslationY, in: containerView)
        let shouldFinish = progress > configuration.sheet.interactiveDismissProgressThreshold
          || abs(velocity.y) > configuration.sheet.dismissVelocityThreshold
        if shouldFinish {
          interactionController.finishDismissal()
          notifyProgress(1)
        } else {
          interactionController.cancelDismissal()
          notifyProgress(0)
          animateToCurrentDetent(animated: true)
        }
        isInteractiveDismissing = false
        return
      }

      let shouldDismiss = sheetShouldDismiss(translationY: translation.y, velocityY: velocity.y, in: containerView)
      if shouldDismiss {
        notifyProgress(1)
        presentedViewController.dismiss(animated: true)
        return
      }

      let targetIndex = nearestDetentIndex(for: wrapperView.frame, in: containerView, velocityY: velocity.y)
      setDetentIndex(targetIndex, animated: true)
      notifyProgress(0)
    default:
      break
    }
  }

  private func sheetMinY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    switch configuration.mode {
    case .topSheet:
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    default:
      break
    }
    // bottom sheet: minY corresponds to largest height
    let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.5
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - maxHeight - extra
  }

  private func sheetMaxY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    switch configuration.mode {
    case .topSheet:
      // For top sheets we keep minY fixed; this is used only by progress computations for bottom sheets.
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    default:
      break
    }
    let minHeight = resolvedDetentHeights.min() ?? 240
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - minHeight - extra
  }

  private func sheetDismissProgress(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    switch configuration.mode {
    case .topSheet:
      let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.6
      let progress = (wrapperView.frame.height - maxHeight) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    default:
      let progress = (sheetMaxY(in: containerView) - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
  }

  private func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat, in containerView: UIView) -> Bool {
    guard configuration.dismissBehavior.allowsSwipe else { return false }
    switch configuration.mode {
    case .bottomSheet:
      // Pulling downward dismisses.
      if translationY > configuration.sheet.dismissThreshold { return true }
      if velocityY > configuration.sheet.dismissVelocityThreshold { return true }
    case .topSheet:
      // Pushing upward dismisses.
      if translationY < -configuration.sheet.dismissThreshold { return true }
      if velocityY < -configuration.sheet.dismissVelocityThreshold { return true }
    default:
      break
    }
    return false
  }

  private func nearestDetentIndex(for frame: CGRect, in containerView: UIView, velocityY: CGFloat) -> Int {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? (safeInsets.top + safeInsets.bottom) : 0
    let availableHeight = bounds.height - extra

    // Convert current y to height.
    let currentHeight: CGFloat
    switch configuration.mode {
    case .bottomSheet:
      let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      currentHeight = bounds.height - frame.minY - bottomExtra
    case .topSheet:
      currentHeight = frame.height
    default:
      currentHeight = min(availableHeight, max(0, frame.height))
    }

    // Velocity hint: move one step if fast.
    if abs(velocityY) > 900, resolvedDetentHeights.count >= 2 {
      switch configuration.mode {
      case .bottomSheet:
        // Upwards swipe (negative y) => larger height.
        return velocityY < 0 ? min(resolvedDetentHeights.count - 1, currentDetentIndex + 1) : max(0, currentDetentIndex - 1)
      case .topSheet:
        // Downwards swipe (positive y) => larger height.
        return velocityY > 0 ? min(resolvedDetentHeights.count - 1, currentDetentIndex + 1) : max(0, currentDetentIndex - 1)
      default:
        break
      }
    }

    if configuration.sheet.enablesMagneticSnapping {
      for (idx, h) in resolvedDetentHeights.enumerated() where abs(h - currentHeight) <= configuration.sheet.magneticSnapThreshold {
        return idx
      }
    }

    var best = 0
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (idx, h) in resolvedDetentHeights.enumerated() {
      let d = abs(h - currentHeight)
      if d < bestDistance {
        bestDistance = d
        best = idx
      }
    }
    return best
  }

  private func setDetentIndex(_ index: Int, animated: Bool) {
    let clamped = max(0, min(index, max(0, resolvedDetentHeights.count - 1)))
    if clamped == currentDetentIndex { animateToCurrentDetent(animated: animated); return }
    currentDetentIndex = clamped
    if configuration.sheet.detents.indices.contains(clamped) {
      notifyDetentDidChange(configuration.sheet.detents[clamped], index: clamped)
      if configuration.haptics.isEnabled {
        let generator = UIImpactFeedbackGenerator(style: configuration.haptics.feedbackStyle)
        generator.impactOccurred()
      }
    }
    animateToCurrentDetent(animated: animated)
  }

  func setDetent(_ detent: FKPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(where: { $0 == detent }) else { return }
    setDetentIndex(index, animated: animated)
  }

  private func animateToCurrentDetent(animated: Bool) {
    guard let containerView else { return }
    let targetFrame = frameOfPresentedViewInContainerView
    let animations = {
      self.wrapperView.frame = targetFrame
      self.chromeView.frame = self.wrapperView.bounds
      self.layoutContentContainer()
      self.embeddedPresentedView?.frame = self.contentContainerView.bounds
      self.applyContainerAppearance()
      self.updateBackdropForCurrentState()
    }
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: animations)
    } else {
      animations()
    }
  }

  private func notifyProgress(_ progress: CGFloat) {
    owner?.notifyProgress(progress)
  }

  private func notifyDetentDidChange(_ detent: FKPresentationDetent, index: Int) {
    owner?.notifyDetentDidChange(detent, index: index)
  }

  private func resolvedSheetWidth(in bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    let availableWidth = bounds.width - safeInsets.left - safeInsets.right
    switch configuration.sheet.widthPolicy {
    case .fill:
      return bounds.width
    case let .fraction(value):
      return min(availableWidth, max(220, availableWidth * min(max(value, 0.2), 1)))
    case let .max(value):
      return min(availableWidth, max(220, value))
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

  private func resolveKeyboardTargetScrollView() -> UIScrollView? {
    if let explicit = configuration.keyboardAvoidance.targetScrollView?.object {
      return explicit
    }
    return findPrimaryScrollView(in: presentedViewController.view)
  }

  private func resolvedTrackedScrollView() -> UIScrollView? {
    switch configuration.sheet.scrollTrackingStrategy {
    case .automatic:
      return findPrimaryScrollView(in: presentedViewController.view)
    case .disabled:
      return nil
    case let .explicit(box):
      return box.object
    }
  }

  private func shouldTransferPanFromScrollView(_ scrollView: UIScrollView, translationY: CGFloat) -> Bool {
    // bottom sheet: drag down should transfer when scroll at top.
    // top sheet: drag up should transfer when scroll at bottom.
    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5

    switch configuration.mode {
    case .bottomSheet:
      if translationY > 0 { return atTop }
      return false
    case .topSheet:
      if translationY < 0 { return atBottom }
      return false
    default:
      return true
    }
  }

  private func shouldEnterInteractiveDismiss(translationY: CGFloat, velocityY: CGFloat) -> Bool {
    switch configuration.mode {
    case .bottomSheet:
      let isAtLowestDetent = currentDetentIndex == 0
      return isAtLowestDetent && (translationY > configuration.sheet.dismissThreshold || velocityY > configuration.sheet.dismissVelocityThreshold)
    case .topSheet:
      let isAtLowestDetent = currentDetentIndex == 0
      return isAtLowestDetent && (translationY < -configuration.sheet.dismissThreshold || velocityY < -configuration.sheet.dismissVelocityThreshold)
    default:
      return false
    }
  }

  private func interactiveDismissProgress(translationY: CGFloat, in containerView: UIView) -> CGFloat {
    let denominator = max(containerView.bounds.height * 0.28, 120)
    let raw: CGFloat
    switch configuration.mode {
    case .bottomSheet:
      raw = translationY / denominator
    case .topSheet:
      raw = -translationY / denominator
    default:
      raw = abs(translationY) / denominator
    }
    return min(max(raw, 0), 1)
  }

  private func clampedContentHeight(_ height: CGFloat, containerView: UIView) -> CGFloat {
    var value = max(0, height)
    if let minimum = configuration.sheet.minimumContentHeight {
      value = max(value, minimum)
    }
    if let maximum = configuration.sheet.maximumContentHeight {
      value = min(value, maximum)
    }
    let safe = containerSafeInsets(in: containerView)
    let maxAvailable = containerView.bounds.height - safe.top - safe.bottom
    return min(value, maxAvailable)
  }

  private func updateBackdropForCurrentState() {
    guard configuration.sheet.multiStageBackdrop.isEnabled else {
      // Respect the configured backdrop intensity. `FKPresentationBackdropView` also uses internal alpha
      // for blur effects, so we keep the container-level alpha as the primary dimming channel only.
      switch configuration.backdropStyle {
      case let .dim(_, alpha):
        backdropView.alpha = alpha
      default:
        backdropView.alpha = 1
      }
      return
    }
    guard let minHeight = resolvedDetentHeights.min(), let maxHeight = resolvedDetentHeights.max(), maxHeight > minHeight else {
      backdropView.alpha = configuration.sheet.multiStageBackdrop.maximumAlpha
      return
    }

    let currentHeight: CGFloat
    switch configuration.mode {
    case .bottomSheet:
      if let containerView {
        let bottomInset = configuration.safeAreaPolicy == .containerRespectsSafeArea ? containerView.safeAreaInsets.bottom : 0
        currentHeight = containerView.bounds.height - wrapperView.frame.minY - bottomInset
      } else {
        currentHeight = wrapperView.frame.height
      }
    default:
      currentHeight = wrapperView.frame.height
    }

    let progress = min(max((currentHeight - minHeight) / (maxHeight - minHeight), 0), 1)
    let low = configuration.sheet.multiStageBackdrop.minimumAlpha
    let high = configuration.sheet.multiStageBackdrop.maximumAlpha
    backdropView.alpha = low + (high - low) * progress
  }

  private func applyPresentingViewEffectIfNeeded(isPresenting: Bool) {
    let effect = configuration.presentingViewEffect
    guard effect.isEnabled, let host = presentingViewController.view else { return }
    if isPresenting, host.window == nil {
      // Presenting controller is disappearing; skip effect safely.
      cleanupPresentingViewEffect()
      return
    }
    presentingEffectHostView = host

    if let style = effect.blurStyle, presentingBlurView == nil {
      let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
      blurView.frame = host.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blurView.alpha = 0
      host.addSubview(blurView)
      presentingBlurView = blurView
    }

    let updates = {
      host.transform = isPresenting ? CGAffineTransform(scaleX: effect.scale, y: effect.scale) : .identity
      self.presentingBlurView?.alpha = isPresenting ? effect.blurAlpha : 0
    }
    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in updates() }
    } else {
      updates()
    }
  }

  private func cleanupPresentingViewEffect() {
    presentingEffectHostView?.transform = .identity
    presentingBlurView?.removeFromSuperview()
    presentingBlurView = nil
    presentingEffectHostView = nil
  }

  private func anchoredFrame(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets, anchor: FKAnchor) -> CGRect {
    let result = FKPresentationAnchorLayout.anchoredFrame(
      in: containerView,
      bounds: bounds,
      safeInsets: safeInsets,
      anchor: anchor,
      measuredContentHeight: { [weak self] in
        guard let self, let containerView = self.containerView else { return 320 }
        return self.measuredFitContentHeight(in: containerView)
      }
    )
    return result.frame
  }

  private func resolveSourceRect(in containerView: UIView, anchor: FKAnchor) -> CGRect? {
    FKPresentationAnchorLayout.resolveSourceRect(in: containerView, anchor: anchor)
  }

  private func edgeFrame(in bounds: CGRect, edge: UIRectEdge) -> CGRect {
    let width = min(bounds.width * 0.85, 420)
    let height = min(bounds.height * 0.85, 640)
    if edge.contains(.left) {
      return CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.right) {
      return CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.top) {
      return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
  }
}

