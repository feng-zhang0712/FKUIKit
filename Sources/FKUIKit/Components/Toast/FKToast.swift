import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Global entry point for lightweight toast/snackbar hints.
public enum FKToast {
  /// App-wide default configuration used by one-line APIs.
  ///
  /// The default is not automatically merged into per-message configuration created by
  /// `FKToastConfiguration(...)`. Set this once at app launch to establish your baseline.
  @MainActor
  public static var defaultConfiguration: FKToastConfiguration {
    get { FKToastCenter.shared.defaultConfiguration }
    set { FKToastCenter.shared.defaultConfiguration = newValue }
  }

  /// Shows a toast/snackbar text message using default configuration.
  ///
  /// - Parameters:
  ///   - message: Message text.
  ///   - style: Visual style level.
  ///   - kind: Presentation kind.
  ///
  /// - Note: This is safe to call from any thread; rendering is always performed on the main actor.
  public static func show(
    _ message: String,
    style: FKToastStyle = .normal,
    kind: FKToastKind = .toast
  ) {
    show(message, configuration: FKToastConfiguration(kind: kind, style: style))
  }

  /// Shows a toast/snackbar message with custom configuration.
  ///
  /// - Parameters:
  ///   - message: Message text.
  ///   - icon: Optional icon. Defaults to style icon when `nil`.
  ///   - configuration: Per-message configuration override.
  ///   - actionHandler: Optional action callback for `configuration.action`.
  ///
  /// - Important: If you set `configuration.action`, pass an `actionHandler` to handle the action.
  ///   The toast will still dismiss even if `actionHandler` is `nil`.
  public static func show(
    _ message: String,
    icon: UIImage? = nil,
    configuration: FKToastConfiguration,
    actionHandler: (() -> Void)? = nil
  ) {
    enqueue(
      FKToastRequest(
        message: message,
        icon: icon,
        customViewProvider: nil,
        configuration: configuration,
        actionHandler: actionHandler
      )
    )
  }

  /// Shows a custom UIKit view as toast content.
  ///
  /// - Parameters:
  ///   - customView: Custom content view.
  ///   - configuration: Per-message configuration override.
  ///   - actionHandler: Optional action callback for `configuration.action`.
  ///
  /// - Note: When providing a custom view, FKToast does not apply default icon/label layout.
  public static func show(
    customView: UIView,
    configuration: FKToastConfiguration = FKToastConfiguration(),
    actionHandler: (() -> Void)? = nil
  ) {
    enqueue(
      FKToastRequest(
        message: nil,
        icon: nil,
        customViewProvider: { customView },
        configuration: configuration,
        actionHandler: actionHandler
      )
    )
  }

#if canImport(SwiftUI)
  /// Shows a custom SwiftUI view as toast content.
  ///
  /// - Parameters:
  ///   - content: SwiftUI content view.
  ///   - configuration: Per-message configuration override.
  ///   - actionHandler: Optional action callback for `configuration.action`.
  ///
  /// - Note: The SwiftUI view is hosted by `UIHostingController` and attached to the top-most
  ///   available window.
  ///
  /// - Important: This overload is `@MainActor` because SwiftUI views are not generally `Sendable`
  ///   and must not be transferred across concurrency domains.
  @MainActor
  public static func show<Content: View>(
    swiftUIView content: Content,
    configuration: FKToastConfiguration = FKToastConfiguration(),
    actionHandler: (() -> Void)? = nil
  ) {
    enqueue(
      FKToastRequest(
        message: nil,
        icon: nil,
        customViewProvider: {
          let host = UIHostingController(rootView: content)
          host.view.backgroundColor = .clear
          return host.view
        },
        configuration: configuration,
        actionHandler: actionHandler
      )
    )
  }
#endif

  /// Hides current toast and clears pending queue.
  ///
  /// - Parameter animated: Whether to animate dismiss.
  ///
  /// - Note: This cancels any scheduled auto-dismiss work and immediately proceeds to cleanup.
  public static func clearAll(animated: Bool = true) {
    Task { @MainActor in
      FKToastCenter.shared.clearAll(animated: animated)
    }
  }

  // Enqueues a request on the main actor for serialized presentation.
  private static func enqueue(_ request: FKToastRequest) {
    Task { @MainActor in
      FKToastCenter.shared.enqueue(request)
    }
  }
}

@MainActor
final class FKToastCenter {
  static let shared = FKToastCenter()

  // Baseline defaults; callers can override per request.
  var defaultConfiguration = FKToastConfiguration()

  // FIFO queue of pending requests. Only one toast is presented at a time.
  private var queue: [FKToastRequest] = []
  // Current live toast, if any.
  private var currentPresentation: FKToastPresentation?
  // Scheduled dismissal task for auto-dismiss.
  private var dismissTask: Task<Void, Never>?

  private init() {}

  fileprivate func enqueue(_ request: FKToastRequest) {
    queue.append(request)
    presentNextIfNeeded()
  }

  func clearAll(animated: Bool) {
    queue.removeAll()
    dismissCurrent(animated: animated)
  }

  private func presentNextIfNeeded() {
    // Prevent stacking: only present when no active toast exists.
    guard currentPresentation == nil else { return }
    guard !queue.isEmpty else { return }
    // If we cannot resolve a window (rare, e.g. app inactive), skip presentation for now.
    guard let window = topWindow() else { return }

    let request = queue.removeFirst()
    let resolvedText = request.message ?? ""
    // When position is not specified, snackbar defaults to bottom and toast defaults to center.
    let resolvedPosition = request.configuration.position ?? (request.configuration.kind == .snackbar ? .bottom : .center)

    let toastView = FKToastView(
      text: resolvedText,
      icon: request.icon,
      customContentView: request.customViewProvider?(),
      configuration: request.configuration
    )

    toastView.onTap = { [weak self] in
      guard let self else { return }
      if request.configuration.tapToDismiss {
        self.dismissCurrent(animated: true)
      }
    }
    toastView.onActionTap = { [weak self] in
      guard let self else { return }
      request.actionHandler?()
      self.dismissCurrent(animated: true)
    }

    if request.configuration.swipeToDismiss {
      // Pan gesture provides "swipe away" interaction with velocity/translation threshold.
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      toastView.addGestureRecognizer(pan)
    }

    // Attach to the window to remain non-invasive and independent of view-controller hierarchy.
    window.addSubview(toastView)
    let width = toastView.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, multiplier: request.configuration.maxWidthRatio)
    width.priority = .required
    let centerX = toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor)
    var positionConstraint: NSLayoutConstraint

    switch resolvedPosition {
    case .top:
      // Top anchored below the visible navigation bar when available; otherwise below safe area.
      let topOffset = resolvedTopOffset(in: window, configuration: request.configuration)
      positionConstraint = toastView.topAnchor.constraint(
        equalTo: window.topAnchor,
        constant: topOffset
      )
    case .center:
      positionConstraint = toastView.centerYAnchor.constraint(
        equalTo: window.safeAreaLayoutGuide.centerYAnchor,
        constant: request.configuration.verticalOffset
      )
    case .bottom:
      // Bottom anchored to safe-area with outer inset and optional offset.
      positionConstraint = toastView.bottomAnchor.constraint(
        equalTo: window.safeAreaLayoutGuide.bottomAnchor,
        constant: -(request.configuration.outerInsets.bottom - request.configuration.verticalOffset)
      )
    }

    NSLayoutConstraint.activate([
      width,
      centerX,
      toastView.leadingAnchor.constraint(greaterThanOrEqualTo: window.safeAreaLayoutGuide.leadingAnchor, constant: request.configuration.outerInsets.leading),
      toastView.trailingAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -request.configuration.outerInsets.trailing),
      positionConstraint,
    ])

    currentPresentation = FKToastPresentation(
      id: request.id,
      view: toastView,
      configuration: request.configuration,
      position: resolvedPosition
    )

    // Perform entrance animation and schedule auto-dismiss if needed.
    FKToastAnimator.animateIn(
      view: toastView,
      kind: request.configuration.kind,
      position: resolvedPosition,
      style: request.configuration.animationStyle,
      duration: request.configuration.animationDuration
    )

    scheduleAutoDismissIfNeeded(configuration: request.configuration)
  }

  private func scheduleAutoDismissIfNeeded(configuration: FKToastConfiguration) {
    // Cancel any previous scheduled task to avoid racing dismissals across queue transitions.
    dismissTask?.cancel()
    dismissTask = nil
    guard configuration.duration > 0 else { return }

    let seconds = configuration.duration
    dismissTask = Task { [weak self] in
      let nanos = UInt64(max(0, seconds) * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanos)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self?.dismissCurrent(animated: true)
      }
    }
  }

  @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
    guard let view = pan.view else { return }
    switch pan.state {
    case .changed:
      // Track vertical translation and fade slightly for tactile feedback.
      let translation = pan.translation(in: view.superview)
      view.transform = CGAffineTransform(translationX: 0, y: translation.y)
      view.alpha = max(0.4, 1 - abs(translation.y) / 160)
    case .ended, .cancelled, .failed:
      let velocity = pan.velocity(in: view.superview).y
      let translation = pan.translation(in: view.superview).y
      // Dismiss when gesture exceeds distance or velocity thresholds.
      if abs(translation) > 44 || abs(velocity) > 500 {
        dismissCurrent(animated: true)
      } else {
        // Restore to identity when user does not commit dismissal.
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
          view.transform = .identity
          view.alpha = 1
        }
      }
    default:
      break
    }
  }

  private func dismissCurrent(animated: Bool) {
    dismissTask?.cancel()
    dismissTask = nil

    guard let presentation = currentPresentation else { return }
    currentPresentation = nil

    // After dismiss, immediately present the next queued item (if any).
    // Wrap cleanup in a `@Sendable` closure to satisfy Swift 6 requirements of animation callbacks.
    let completion: @Sendable () -> Void = { [weak self] in
      Task { @MainActor in
        presentation.view.removeFromSuperview()
        self?.presentNextIfNeeded()
      }
    }

    guard animated else {
      completion()
      return
    }

    FKToastAnimator.animateOut(
      view: presentation.view,
      position: presentation.position,
      style: presentation.configuration.animationStyle,
      duration: presentation.configuration.animationDuration,
      completion: completion
    )
  }

  private func resolvedTopOffset(in window: UIWindow, configuration: FKToastConfiguration) -> CGFloat {
    let safeTop = window.safeAreaInsets.top
    let navBottom = currentNavigationBarBottom(in: window) ?? safeTop
    return max(safeTop, navBottom) + configuration.outerInsets.top + configuration.verticalOffset
  }

  private func currentNavigationBarBottom(in window: UIWindow) -> CGFloat? {
    guard let topVC = topViewController(from: window.rootViewController) else { return nil }
    let nav = topVC.navigationController
    guard
      let nav,
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

  private func topWindow() -> UIWindow? {
    // Prefer the foreground active scene to work correctly in multi-window iPadOS setups.
    let activeScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }

    for scene in activeScenes {
      if let key = scene.windows.first(where: { $0.isKeyWindow }) {
        return key
      }
      if let normal = scene.windows.first(where: { !$0.isHidden && $0.alpha > 0 && $0.windowLevel == .normal }) {
        return normal
      }
    }
    // Fallback for older patterns; should be rare on iOS 13+ when scenes are enabled.
    return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
  }
}

/// Internal request model stored by the global queue.
///
/// - Important: This type is confined to the main actor via `FKToastCenter`, but requests are
///   created on arbitrary threads. Marked as `@unchecked Sendable` to satisfy Swift 6 concurrency
///   diagnostics while keeping `UIImage`/`UIView` and callback closures as implementation details.
private struct FKToastRequest: @unchecked Sendable {
  // Stable identity for the request lifecycle.
  let id = UUID()
  // Optional plain message string.
  let message: String?
  // Optional explicit icon. When nil, style icon is used.
  let icon: UIImage?
  // Optional provider for custom UIKit content.
  let customViewProvider: (() -> UIView)?
  // Per-request configuration.
  let configuration: FKToastConfiguration
  // Optional action handler invoked on action tap.
  let actionHandler: (() -> Void)?
}

/// Internal presentation record for the currently visible toast.
private struct FKToastPresentation: @unchecked Sendable {
  // Request identity for the currently presented toast.
  let id: UUID
  // Rendered toast view instance.
  let view: FKToastView
  // Configuration snapshot used during presentation.
  let configuration: FKToastConfiguration
  // Resolved position used for layout/animation.
  let position: FKToastPosition
}
