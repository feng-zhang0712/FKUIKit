import AudioToolbox
import UIKit

/// Main-actor singleton that attaches overlays to the key window, drives the queue actor, and owns timers.
@MainActor
final class FKToastCenter {
  static let shared = FKToastCenter()

  var defaultConfiguration = FKToastConfiguration()

  private let queueActor = FKToastQueueActor()
  private var current: [UUID: FKToastPresentation] = [:]
  private var dismissTasks: [UUID: Task<Void, Never>] = [:]
  private var blockers: [UUID: FKToastBlockingView] = [:]
  private var keyboardHeight: CGFloat = 0

  var isPresenting: Bool { !current.isEmpty }

  private init() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(sceneDidDisconnect(_:)), name: UIScene.didDisconnectNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(windowMetricsMayChange), name: UIDevice.orientationDidChangeNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func enqueue(builder: FKToastBuilder, id: UUID = UUID()) -> UUID {
    let request = FKToastRequest(
      id: id,
      content: builder.content,
      icon: builder.icon,
      configuration: builder.configuration,
      hooks: builder.hooks,
      actionHandler: builder.actionHandler,
      secondaryActionHandler: builder.secondaryActionHandler,
      createdAt: Date()
    )
    Task {
      if let interrupt = await queueActor.enqueue(request) {
        await MainActor.run {
          dismissTopMost(reason: .interruptedByPriority, enqueueAfterDismiss: interrupt)
        }
      }
      await MainActor.run {
        presentNextIfNeeded()
      }
    }
    return id
  }

  func clearAll(animated: Bool) {
    Task {
      _ = await queueActor.clear()
      await MainActor.run {
        for id in current.keys {
          dismiss(id: id, reason: .manual, animated: animated)
        }
      }
    }
  }

  func dismiss(id: UUID, reason: FKToastDismissReason = .manual, animated: Bool = true) {
    guard let presentation = current[id] else { return }
    presentation.request.hooks.willDismiss?(id, reason)
    dismissTasks[id]?.cancel()
    dismissTasks[id] = nil
    current[id] = nil
    Task { await queueActor.markDismissed(id: id) }

    let completion: () -> Void = { [weak self] in
      Task { @MainActor in
        self?.blockers[id]?.removeFromSuperview()
        self?.blockers[id] = nil
        presentation.view.removeFromSuperview()
        presentation.request.hooks.didDismiss?(id, reason)
        self?.presentNextIfNeeded()
      }
    }
    guard animated else {
      completion()
      return
    }
    FKToastAnimator.animateOut(
      view: presentation.view,
      position: presentation.resolvedPosition,
      style: presentation.request.configuration.animationStyle,
      duration: presentation.request.configuration.animationDuration,
      completion: completion
    )
  }

  func update(id: UUID, content: FKToastContent, configuration: FKToastConfiguration? = nil) -> Bool {
    guard let presentation = current[id] else { return false }
    let previous = presentation.request
    let updatedRequest = FKToastRequest(
      id: previous.id,
      content: content,
      icon: previous.icon,
      configuration: configuration ?? previous.configuration,
      hooks: previous.hooks,
      actionHandler: previous.actionHandler,
      secondaryActionHandler: previous.secondaryActionHandler,
      createdAt: previous.createdAt
    )
    presentation.request = updatedRequest
    presentation.view.updateDisplayedRequest(updatedRequest)
    syncSwipeGestureRecognizer(on: presentation.view, swipeToDismiss: updatedRequest.configuration.swipeToDismiss)
    Task { await queueActor.updateDisplayed(updatedRequest) }
    return true
  }

  func updateProgress(id: UUID, progress: Double, title: String? = nil) -> Bool {
    guard let presentation = current[id] else { return false }
    let clampedProgress = min(max(progress, 0), 1)
    let percent = Int((clampedProgress * 100).rounded())
    let progressText = "\(percent)%"
    let resolvedTitle: String = {
      if let title, !title.isEmpty {
        return title
      }
      switch presentation.request.content {
      case let .titleSubtitle(currentTitle, _):
        return currentTitle
      case let .message(message):
        return message
      case .customView:
        return presentation.request.configuration.localizedText.loadingText
      }
    }()
    return update(id: id, content: .titleSubtitle(title: resolvedTitle, subtitle: progressText))
  }

  private func presentNextIfNeeded() {
    let maxCount = defaultConfiguration.queue.maxConcurrentDisplayCount
    Task {
      let requests = await queueActor.claimNext(maxCount: maxCount)
      guard !requests.isEmpty else { return }
      for request in requests {
        await MainActor.run {
          present(request: request)
        }
      }
    }
  }

  private func present(request: FKToastRequest) {
    guard let window = topWindow() else { return }
    let resolvedPosition = resolvedPosition(for: request.configuration)
    let toastView = FKToastView(request: request)
    if request.configuration.interceptTouches {
      let blocker = FKToastBlockingView(frame: window.bounds)
      blocker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blocker.backgroundColor = .clear
      blocker.passthroughRects = request.configuration.passthroughRects
      window.addSubview(blocker)
      blockers[request.id] = blocker
    }

    toastView.onTap = { [weak self] in
      guard let self else { return }
      if request.configuration.tapToDismiss {
        self.dismiss(id: request.id, reason: .userTap)
      }
    }
    toastView.onLongPress = { [weak self] in
      guard let self else { return }
      self.dismiss(id: request.id, reason: .userLongPress)
    }
    toastView.onPrimaryActionTap = { [weak self] in
      guard let self else { return }
      request.actionHandler?()
      self.dismiss(id: request.id, reason: .actionTriggered)
    }
    toastView.onSecondaryActionTap = { [weak self] in
      guard let self else { return }
      request.secondaryActionHandler?()
      self.dismiss(id: request.id, reason: .actionTriggered)
    }

    syncSwipeGestureRecognizer(on: toastView, swipeToDismiss: request.configuration.swipeToDismiss)

    let hostView = blockers[request.id] ?? window
    hostView.addSubview(toastView)
    let maxWidth = toastView.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: request.configuration.maxWidthRatio)
    let centerX = toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor)
    let positionConstraint = positionConstraint(for: toastView, window: window, position: resolvedPosition, configuration: request.configuration)
    NSLayoutConstraint.activate([
      maxWidth,
      centerX,
      toastView.leadingAnchor.constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leadingAnchor, constant: request.configuration.outerInsets.leading),
      toastView.trailingAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -request.configuration.outerInsets.trailing),
      positionConstraint,
    ])

    let presentation = FKToastPresentation(request: request, view: toastView, resolvedPosition: resolvedPosition, positionConstraint: positionConstraint, hostWindow: window)
    current[request.id] = presentation
    request.hooks.willShow?(request.id)
    playSound(request.configuration.sound)
    FKToastAnimator.animateIn(
      view: toastView,
      kind: request.configuration.kind,
      position: resolvedPosition,
      style: request.configuration.animationStyle,
      duration: request.configuration.animationDuration
    ) { [weak self] in
      Task { @MainActor in
        request.hooks.didShow?(request.id)
        self?.announceIfNeeded(request)
      }
    }
    scheduleAutoDismiss(for: request.id, configuration: request.configuration)
  }

  private func playSound(_ sound: FKToastSound) {
    switch sound {
    case .none:
      return
    case .default:
      AudioServicesPlaySystemSound(1001)
    case let .custom(url):
      var soundID: SystemSoundID = 0
      AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
      guard soundID != 0 else { return }
      AudioServicesPlaySystemSound(soundID)
      AudioServicesDisposeSystemSoundID(soundID)
    }
  }

  private func scheduleAutoDismiss(for id: UUID, configuration: FKToastConfiguration) {
    dismissTasks[id]?.cancel()
    let timeout = configuration.timeout ?? configuration.duration
    guard timeout > 0 else { return }
    dismissTasks[id] = Task { [weak self] in
      try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self?.dismiss(id: id, reason: .timeout)
      }
    }
  }

  private func syncSwipeGestureRecognizer(on toastView: FKToastView, swipeToDismiss: Bool) {
    for recognizer in toastView.gestureRecognizers ?? [] where recognizer is UIPanGestureRecognizer {
      toastView.removeGestureRecognizer(recognizer)
    }
    if swipeToDismiss {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      toastView.addGestureRecognizer(pan)
    }
  }

  private func announceIfNeeded(_ request: FKToastRequest) {
    guard request.configuration.accessibilityAnnouncementEnabled else { return }
    if let override = request.configuration.accessibilityAnnouncementOverride, !override.isEmpty {
      UIAccessibility.post(notification: .announcement, argument: override)
      return
    }
    let text: String
    switch request.content {
    case let .message(message):
      text = message
    case let .titleSubtitle(title, subtitle):
      text = "\(title). \(subtitle)"
    case .customView:
      text = ""
    }
    guard !text.isEmpty else { return }
    UIAccessibility.post(notification: .announcement, argument: text)
  }

  private func dismissTopMost(reason: FKToastDismissReason, enqueueAfterDismiss request: FKToastRequest) {
    guard let top = current.values.sorted(by: { $0.request.configuration.priority < $1.request.configuration.priority }).last else { return }
    dismiss(id: top.request.id, reason: reason, animated: true)
    Task {
      _ = await queueActor.enqueue(request)
    }
  }

  private func resolvedPosition(for configuration: FKToastConfiguration) -> FKToastPosition {
    if let position = configuration.position { return position }
    switch configuration.kind {
    case .toast: return .center
    case .hud: return .center
    case .snackbar: return .bottom
    }
  }

  private func positionConstraint(for view: UIView, window: UIWindow, position: FKToastPosition, configuration: FKToastConfiguration) -> NSLayoutConstraint {
    switch position {
    case .top:
      let offset = resolvedTopOffset(in: window, configuration: configuration)
      return view.topAnchor.constraint(equalTo: window.topAnchor, constant: offset)
    case .center:
      return view.centerYAnchor.constraint(equalTo: window.safeAreaLayoutGuide.centerYAnchor, constant: configuration.verticalOffset)
    case .bottom:
      let offset = resolvedBottomOffset(in: window, configuration: configuration)
      return view.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -(offset - configuration.verticalOffset))
    }
  }

  private func resolvedTopOffset(in window: UIWindow, configuration: FKToastConfiguration) -> CGFloat {
    if let navigationBottom = currentNavigationBarBottom(in: window) {
      return navigationBottom + configuration.topInsetWhenHasNavigationBar + configuration.outerInsets.top + configuration.verticalOffset
    }
    return window.safeAreaInsets.top + configuration.topInsetFromSafeArea + configuration.outerInsets.top + configuration.verticalOffset
  }

  private func resolvedBottomOffset(in window: UIWindow, configuration: FKToastConfiguration) -> CGFloat {
    let safeAreaOffset = window.safeAreaInsets.bottom + configuration.bottomInsetFromSafeArea + configuration.outerInsets.bottom
    let tabBarOffset: CGFloat = {
      guard let tabBarTop = currentTabBarTop(in: window) else { return safeAreaOffset }
      let tabBarHeightFromBottom = max(0, window.bounds.maxY - tabBarTop)
      return tabBarHeightFromBottom + configuration.bottomInsetWhenHasTabBar + configuration.outerInsets.bottom
    }()
    let keyboardOffset = keyboardHeight + configuration.bottomInsetFromSafeArea + configuration.outerInsets.bottom
    return max(tabBarOffset, safeAreaOffset, keyboardOffset)
  }

  @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
    guard let view = pan.view as? FKToastView else { return }
    switch pan.state {
    case .changed:
      let translation = pan.translation(in: view.superview)
      view.transform = CGAffineTransform(translationX: 0, y: translation.y)
      view.alpha = max(0.42, 1 - abs(translation.y) / 180)
    case .ended, .cancelled:
      let translation = pan.translation(in: view.superview).y
      let velocity = pan.velocity(in: view.superview).y
      if abs(translation) > 44 || abs(velocity) > 520 {
        if let target = current.first(where: { $0.value.view === view }) {
          dismiss(id: target.key, reason: .userSwipe)
        }
      } else {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
          view.alpha = 1
          view.transform = .identity
        }
      }
    default:
      break
    }
  }

  @objc private func keyboardWillChange(_ note: Notification) {
    guard
      let frameValue = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
      let window = topWindow()
    else { return }
    let localFrame = window.convert(frameValue.cgRectValue, from: nil)
    keyboardHeight = max(0, window.bounds.maxY - localFrame.minY)
    let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    let curveRaw = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
    refreshLayoutConstraintsForActivePresentations(animationDuration: duration, animationCurveRawValue: curveRaw)
  }

  @objc private func sceneDidDisconnect(_ note: Notification) {
    for item in current where item.value.view.window?.windowScene === note.object as? UIWindowScene {
      dismiss(id: item.key, reason: .sceneDestroyed, animated: false)
    }
  }

  @objc private func windowMetricsMayChange() {
    refreshLayoutConstraintsForActivePresentations()
  }

  private func refreshLayoutConstraintsForActivePresentations(
    animationDuration: TimeInterval? = nil,
    animationCurveRawValue: UInt? = nil
  ) {
    for (_, presentation) in current {
      guard let window = presentation.hostWindow else { continue }
      switch presentation.resolvedPosition {
      case .center:
        presentation.positionConstraint.constant = presentation.request.configuration.verticalOffset
      case .top:
        presentation.positionConstraint.constant = resolvedTopOffset(in: window, configuration: presentation.request.configuration)
      case .bottom:
        let offset = resolvedBottomOffset(in: window, configuration: presentation.request.configuration)
        presentation.positionConstraint.constant = -(offset - presentation.request.configuration.verticalOffset)
      }
      if
        let animationDuration,
        let animationCurveRawValue
      {
        UIView.animate(
          withDuration: animationDuration,
          delay: 0,
          options: UIView.AnimationOptions(rawValue: animationCurveRawValue << 16).union([.beginFromCurrentState, .allowUserInteraction])
        ) {
          window.layoutIfNeeded()
        }
      } else {
        window.layoutIfNeeded()
      }
    }
  }

  private func currentNavigationBarBottom(in window: UIWindow) -> CGFloat? {
    guard
      let topVC = topViewController(from: window.rootViewController),
      let nav = topVC.navigationController,
      !nav.isNavigationBarHidden,
      nav.navigationBar.alpha > 0.01,
      nav.navigationBar.bounds.height > 0,
      nav.navigationBar.window === window
    else {
      return nil
    }
    return nav.navigationBar.convert(nav.navigationBar.bounds, to: window).maxY
  }

  private func currentTabBarTop(in window: UIWindow) -> CGFloat? {
    guard
      let topVC = topViewController(from: window.rootViewController),
      let tabBar = topVC.tabBarController?.tabBar,
      !tabBar.isHidden,
      tabBar.alpha > 0.01,
      tabBar.bounds.height > 0,
      tabBar.window === window
    else {
      return nil
    }
    return tabBar.convert(tabBar.bounds, to: window).minY
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    guard let root else { return nil }
    if let presented = root.presentedViewController { return topViewController(from: presented) }
    if let nav = root as? UINavigationController { return topViewController(from: nav.visibleViewController ?? nav.topViewController) }
    if let tab = root as? UITabBarController { return topViewController(from: tab.selectedViewController) }
    for child in root.children.reversed() {
      if child.viewIfLoaded?.window != nil {
        return topViewController(from: child)
      }
    }
    return root
  }

  private func topWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.filter { $0.activationState == .foregroundActive }
    for scene in scenes {
      if let key = scene.windows.first(where: \.isKeyWindow) { return key }
      if let normal = scene.windows.first(where: { !$0.isHidden && $0.windowLevel == .normal }) { return normal }
    }
    return UIApplication.shared.windows.first(where: \.isKeyWindow) ?? UIApplication.shared.windows.first
  }
}
