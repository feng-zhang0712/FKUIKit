import UIKit
import AudioToolbox

/// Handle object returned from `FKTopNotification.show(...)`.
public final class FKTopNotificationHandle: @unchecked Sendable {
  /// Internal identifier for this notification request.
  fileprivate let id: UUID

  fileprivate init(id: UUID) {
    self.id = id
  }

  /// Hides this notification if it is visible or queued.
  ///
  /// - Parameter animated: Whether to animate the dismissal.
  public func hide(animated: Bool = true) {
    FKTopNotification.hide(id: id, animated: animated)
  }

  /// Updates the notification progress if progress mode is enabled.
  ///
  /// - Parameter progress: A value in `0...1`.
  ///
  /// - Note: Calling this method on a non-progress notification is a no-op.
  public func updateProgress(_ progress: Float) {
    FKTopNotification.updateProgress(id: id, progress: progress)
  }
}

/// Global top floating notification entry.
public enum FKTopNotification {
  /// App-wide default configuration used by one-line APIs.
  @MainActor
  public static var defaultConfiguration: FKTopNotificationConfiguration {
    get { FKTopNotificationCenter.shared.defaultConfiguration }
    set { FKTopNotificationCenter.shared.defaultConfiguration = newValue }
  }

  /// Shows a standard style notification with only title text.
  ///
  /// - Parameters:
  ///   - title: Primary title text.
  ///   - style: Preset visual style.
  /// - Returns: A handle that can update progress or dismiss this request.
  @discardableResult
  public static func show(
    _ title: String,
    style: FKTopNotificationStyle = .normal
  ) -> FKTopNotificationHandle {
    show(title: title, subtitle: nil, icon: nil, configuration: FKTopNotificationConfiguration(style: style))
  }

  /// Shows a notification with UIKit content.
  ///
  /// - Parameters:
  ///   - title: Main title text.
  ///   - subtitle: Secondary subtitle text.
  ///   - icon: Optional leading icon. Uses style icon when `nil`.
  ///   - configuration: Per-message configuration.
  ///   - progress: Optional progress value in `0...1`.
  ///   - onTap: Called when user taps notification body.
  ///   - onAction: Called when user taps trailing action.
  /// - Returns: A handle that can update progress or dismiss this request.
  ///
  /// - Note: Pass `configuration` as `nil` to use `defaultConfiguration`.
  @discardableResult
  public static func show(
    title: String?,
    subtitle: String? = nil,
    icon: UIImage? = nil,
    configuration: FKTopNotificationConfiguration? = nil,
    progress: Float? = nil,
    onTap: (() -> Void)? = nil,
    onAction: (() -> Void)? = nil
  ) -> FKTopNotificationHandle {
    let request = FKTopNotificationRequest(
      title: title,
      subtitle: subtitle,
      icon: icon,
      customViewProvider: nil,
      configuration: configuration,
      progress: progress,
      onTap: onTap,
      onAction: onAction
    )
    enqueue(request)
    return FKTopNotificationHandle(id: request.id)
  }

  /// Shows a custom UIKit view.
  ///
  /// - Parameters:
  ///   - customView: Fully custom UIKit content view.
  ///   - configuration: Optional per-message override configuration.
  ///   - onTap: Callback invoked when body tap is received.
  ///   - onAction: Callback invoked when action button is tapped.
  /// - Returns: A handle that can dismiss this request.
  ///
  /// - Note: When custom view is used, default title/subtitle/icon layout is bypassed.
  @discardableResult
  public static func show(
    customView: UIView,
    configuration: FKTopNotificationConfiguration? = nil,
    onTap: (() -> Void)? = nil,
    onAction: (() -> Void)? = nil
  ) -> FKTopNotificationHandle {
    let request = FKTopNotificationRequest(
      title: nil,
      subtitle: nil,
      icon: nil,
      customViewProvider: { customView },
      configuration: configuration,
      progress: nil,
      onTap: onTap,
      onAction: onAction
    )
    enqueue(request)
    return FKTopNotificationHandle(id: request.id)
  }

  /// Hides the currently showing notification.
  ///
  /// - Parameter animated: Whether to animate the dismissal transition.
  public static func hideCurrent(animated: Bool = true) {
    Task { @MainActor in
      FKTopNotificationCenter.shared.hideCurrent(animated: animated)
    }
  }

  /// Hides notification by handle id. It works for both queued and visible notifications.
  ///
  /// - Parameters:
  ///   - id: Target notification identifier.
  ///   - animated: Whether to animate dismissing the currently displayed item.
  public static func hide(id: UUID, animated: Bool = true) {
    Task { @MainActor in
      FKTopNotificationCenter.shared.hide(id: id, animated: animated)
    }
  }

  /// Updates progress for a queued or visible notification.
  ///
  /// - Parameters:
  ///   - id: Target notification identifier.
  ///   - progress: Progress value in `0...1`.
  public static func updateProgress(id: UUID, progress: Float) {
    Task { @MainActor in
      FKTopNotificationCenter.shared.updateProgress(id: id, progress: progress)
    }
  }

  /// Clears current and all queued notifications.
  ///
  /// - Parameter animated: Whether to animate dismissing the current visible item.
  public static func clearAll(animated: Bool = true) {
    Task { @MainActor in
      FKTopNotificationCenter.shared.clearAll(animated: animated)
    }
  }

  private static func enqueue(_ request: FKTopNotificationRequest) {
    Task { @MainActor in
      FKTopNotificationCenter.shared.enqueue(request)
    }
  }
}

@MainActor
final class FKTopNotificationCenter {
  static let shared = FKTopNotificationCenter()

  // App-level baseline configuration used when a request does not provide its own configuration.
  var defaultConfiguration = FKTopNotificationConfiguration()
  // FIFO-like queue with priority insertion.
  private var queue: [FKTopNotificationRequest] = []
  // Currently rendered notification card.
  private var current: FKTopNotificationPresentation?
  // Auto-dismiss task for the active notification.
  private var dismissTask: Task<Void, Never>?

  private init() {}

  fileprivate func enqueue(_ request: FKTopNotificationRequest) {
    let requestConfig = resolveConfiguration(for: request.configuration)
    // Preempt current notification when a higher priority request arrives.
    if let current, requestConfig.priority > resolveConfiguration(for: current.request.configuration).priority {
      queue.insert(current.request, at: 0)
      hideCurrent(animated: true)
    }
    // Insert request into queue according to its priority and show if idle.
    insertByPriority(request)
    presentNextIfNeeded()
  }

  func hideCurrent(animated: Bool) {
    // Cancel pending auto-dismiss to avoid duplicate dismissal races.
    dismissTask?.cancel()
    dismissTask = nil
    guard let current else { return }
    self.current = nil
    let config = resolveConfiguration(for: current.request.configuration)

    let completion: @Sendable () -> Void = { [weak self] in
      Task { @MainActor in
        // Ensure view cleanup before presenting the next queued item.
        current.view.removeFromSuperview()
        self?.presentNextIfNeeded()
      }
    }

    guard animated else {
      completion()
      return
    }

    FKTopNotificationAnimator.animateOut(
      view: current.view,
      style: config.animationStyle,
      duration: config.animationDuration,
      curve: config.animationCurve,
      completion: completion
    )
  }

  func hide(id: UUID, animated: Bool) {
    // If target is currently visible, dismiss it immediately.
    if current?.request.id == id {
      hideCurrent(animated: animated)
      return
    }
    // Otherwise remove pending request from queue.
    queue.removeAll { $0.id == id }
  }

  func updateProgress(id: UUID, progress: Float) {
    // Update active card in place for smooth progress rendering.
    if current?.request.id == id {
      current?.view.updateProgress(progress)
      current?.request.progress = min(max(progress, 0), 1)
      return
    }
    // Keep queued progress value updated before it gets presented.
    if let idx = queue.firstIndex(where: { $0.id == id }) {
      queue[idx].progress = min(max(progress, 0), 1)
    }
  }

  func clearAll(animated: Bool) {
    // Flush pending queue first, then dismiss any active item.
    queue.removeAll()
    hideCurrent(animated: animated)
  }

  private func presentNextIfNeeded() {
    // Only render when no active card is visible and queue is not empty.
    guard current == nil, !queue.isEmpty else { return }
    // Resolve active foreground window to keep this component globally non-invasive.
    guard let window = topWindow() else { return }

    let request = queue.removeFirst()
    let config = resolveConfiguration(for: request.configuration)
    let card = FKTopNotificationCardView(
      title: request.title,
      subtitle: request.subtitle,
      icon: request.icon,
      customContentView: request.customViewProvider?(),
      progress: request.progress,
      configuration: config
    )

    card.onTap = { [weak self] in
      request.onTap?()
      // Dismiss on tap only when enabled by configuration.
      if config.tapToDismiss {
        self?.hideCurrent(animated: true)
      }
    }
    card.onActionTap = { [weak self] in
      request.onAction?()
      // Action tap always dismisses to match common banner interaction expectations.
      self?.hideCurrent(animated: true)
    }
    card.onCloseBySwipe = { [weak self] in
      self?.hideCurrent(animated: true)
    }

    window.addSubview(card)
    // Resolve final Y position:
    // - If a visible navigation bar exists, place below it.
    // - Otherwise, place below the top safe area (notch / Dynamic Island aware).
    let topOffset = resolvedTopOffset(in: window, configuration: config)
    NSLayoutConstraint.activate([
      card.centerXAnchor.constraint(equalTo: window.centerXAnchor),
      card.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: config.maxWidthRatio),
      card.leadingAnchor.constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leadingAnchor, constant: config.outerInsets.leading),
      card.trailingAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -config.outerInsets.trailing),
      card.topAnchor.constraint(equalTo: window.topAnchor, constant: topOffset),
    ])

    current = FKTopNotificationPresentation(request: request, view: card)
    // Trigger optional sound, then animate and schedule auto-dismiss.
    playSound(config.sound)
    FKTopNotificationAnimator.animateIn(
      view: card,
      style: config.animationStyle,
      duration: config.animationDuration,
      curve: config.animationCurve
    )
    scheduleDismissIfNeeded(duration: config.duration)
  }

  private func scheduleDismissIfNeeded(duration: TimeInterval) {
    // Replace old task to prevent orphaned auto-dismiss callbacks.
    dismissTask?.cancel()
    dismissTask = nil
    guard duration > 0 else { return }
    dismissTask = Task { [weak self] in
      // Convert seconds to nanoseconds for Task sleep API.
      try? await Task.sleep(nanoseconds: UInt64(max(0, duration) * 1_000_000_000))
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self?.hideCurrent(animated: true)
      }
    }
  }

  private func insertByPriority(_ request: FKTopNotificationRequest) {
    guard !queue.isEmpty else {
      queue.append(request)
      return
    }
    let requestConfig = resolveConfiguration(for: request.configuration)
    // Insert ahead of the first lower-priority request; otherwise append at the tail.
    if let idx = queue.firstIndex(where: {
      requestConfig.priority > resolveConfiguration(for: $0.configuration).priority
    }) {
      queue.insert(request, at: idx)
    } else {
      queue.append(request)
    }
  }

  private func resolveConfiguration(for requestConfig: FKTopNotificationConfiguration?) -> FKTopNotificationConfiguration {
    // Per-request config has precedence; fallback to global defaults.
    requestConfig ?? defaultConfiguration
  }

  private func topWindow() -> UIWindow? {
    // Prefer foreground-active scene windows for multi-scene correctness on iPadOS/iOS.
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    for scene in scenes {
      if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
        return keyWindow
      }
      // Fallback to first visible normal-level window when no key window is available.
      if let fallback = scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal }) {
        return fallback
      }
    }
    // Legacy fallback for older window access patterns.
    return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
  }

  private func resolvedTopOffset(in window: UIWindow, configuration: FKTopNotificationConfiguration) -> CGFloat {
    let safeTop = window.safeAreaInsets.top
    let navBottom = currentNavigationBarBottom(in: window) ?? safeTop
    return max(safeTop, navBottom) + configuration.outerInsets.top
  }

  private func currentNavigationBarBottom(in window: UIWindow) -> CGFloat? {
    guard let topVC = topViewController(from: window.rootViewController) else { return nil }
    guard let nav = topVC.navigationController else { return nil }
    guard
      !nav.isNavigationBarHidden,
      nav.navigationBar.alpha > 0.01,
      nav.navigationBar.bounds.height > 0,
      nav.navigationBar.window === window
    else {
      return nil
    }
    return nav.navigationBar.convert(nav.navigationBar.bounds, to: window).maxY
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    guard let root else { return nil }
    if let presented = root.presentedViewController {
      return topViewController(from: presented)
    }
    if let nav = root as? UINavigationController {
      return topViewController(from: nav.visibleViewController ?? nav.topViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    return root
  }

  private func playSound(_ sound: FKTopNotificationSound) {
    switch sound {
    case .none:
      return
    case .default:
      // Built-in system sound for lightweight confirmation feedback.
      AudioServicesPlaySystemSound(1001)
    case .custom(let url):
      // Create and play one-shot custom system sound.
      var soundID: SystemSoundID = 0
      AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
      guard soundID != 0 else { return }
      AudioServicesPlaySystemSound(soundID)
      AudioServicesDisposeSystemSoundID(soundID)
    }
  }
}

private struct FKTopNotificationRequest: @unchecked Sendable {
  let id = UUID()
  let title: String?
  let subtitle: String?
  let icon: UIImage?
  let customViewProvider: (() -> UIView)?
  let configuration: FKTopNotificationConfiguration?
  var progress: Float?
  let onTap: (() -> Void)?
  let onAction: (() -> Void)?
}

private struct FKTopNotificationPresentation: @unchecked Sendable {
  var request: FKTopNotificationRequest
  let view: FKTopNotificationCardView
}
