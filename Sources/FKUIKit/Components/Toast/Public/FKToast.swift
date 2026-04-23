import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Unified entry point for Toast, HUD, and Snackbar overlays.
public enum FKToast {
  /// Global baseline used by convenience APIs.
  ///
  /// Set this during app startup to define default typography, spacing, interaction,
  /// queue policy, and accessibility behavior for all subsequent requests.
  @MainActor
  public static var defaultConfiguration: FKToastConfiguration {
    get { FKToastCenter.shared.defaultConfiguration }
    set { FKToastCenter.shared.defaultConfiguration = newValue }
  }

  /// Shows a lightweight message using one-line defaults.
  ///
  /// - Parameters:
  ///   - message: Visible text announced to users and VoiceOver.
  ///   - style: Semantic style used for icon and color presets.
  ///   - kind: Overlay category (`toast`, `hud`, or `snackbar`).
  ///
  /// This API is thread-safe. Internal rendering always happens on the main actor.
  public static func show(
    _ message: String,
    style: FKToastStyle = .normal,
    kind: FKToastKind = .toast
  ) {
    show(
      builder: .init(
        content: .message(message),
        configuration: FKToastConfiguration(kind: kind, style: style)
      )
    )
  }

  /// Shows a message with full request configuration.
  ///
  /// - Parameters:
  ///   - message: Main textual payload.
  ///   - icon: Optional explicit icon. If `nil`, style defaults are used.
  ///   - configuration: Request-level display and interaction options.
  ///   - hooks: Lifecycle callbacks for show and dismiss phases.
  ///   - actionHandler: Closure executed when the primary action is tapped.
  ///
  /// Use this API when you need queue policy tuning, touch interception, lifecycle telemetry,
  /// or custom timeout behavior.
  public static func show(
    _ message: String,
    icon: UIImage? = nil,
    configuration: FKToastConfiguration,
    hooks: FKToastLifecycleHooks = .init(),
    actionHandler: (@MainActor () -> Void)? = nil
  ) {
    show(
      builder: .init(
        content: .message(message),
        icon: icon,
        configuration: configuration,
        hooks: hooks,
        actionHandler: actionHandler
      )
    )
  }

  /// Shows a custom UIKit view inside the overlay container.
  ///
  /// - Parameters:
  ///   - customView: Caller-owned content view.
  ///   - configuration: Request-level display and interaction options.
  ///   - hooks: Lifecycle callbacks for show and dismiss phases.
  ///   - actionHandler: Closure executed when the primary action is tapped.
  ///
  /// The custom view is embedded without additional text layout, making this suitable for
  /// fully branded or compositional content blocks.
  public static func show(
    customView: UIView,
    configuration: FKToastConfiguration = FKToastConfiguration(),
    hooks: FKToastLifecycleHooks = .init(),
    actionHandler: (@MainActor () -> Void)? = nil
  ) {
    show(
      builder: .init(
        content: .customView { customView },
        configuration: configuration,
        hooks: hooks,
        actionHandler: actionHandler
      )
    )
  }

#if canImport(SwiftUI)
  /// Shows a SwiftUI view by bridging into UIKit hosting.
  ///
  /// - Parameters:
  ///   - content: SwiftUI content rendered inside a `UIHostingController`.
  ///   - configuration: Request-level display and interaction options.
  ///   - hooks: Lifecycle callbacks for show and dismiss phases.
  ///   - actionHandler: Closure executed when the primary action is tapped.
  ///
  /// This overload is `@MainActor` because SwiftUI view values are not guaranteed to be sendable
  /// across concurrency domains.
  @MainActor
  public static func show<Content: View>(
    swiftUIView content: Content,
    configuration: FKToastConfiguration = FKToastConfiguration(),
    hooks: FKToastLifecycleHooks = .init(),
    actionHandler: (@MainActor () -> Void)? = nil
  ) {
    show(
      builder: .swiftUIView(content, configuration: configuration).copy(
        configuration: configuration,
        hooks: hooks,
        actionHandler: actionHandler
      )
    )
  }
#endif

  /// Enqueues one advanced request.
  ///
  /// - Parameters:
  ///   - builder: Content and behavior descriptor.
  /// - Note: This API is thread-safe and internally marshals work to the main actor.
  /// Enqueues one advanced request built via `FKToastBuilder`.
  ///
  /// - Parameter builder: Builder containing content, style, queue policy, and callbacks.
  public static func show(builder: FKToastBuilder) {
    Task { @MainActor in
      _ = FKToastCenter.shared.enqueue(builder: builder)
    }
  }

  /// Asynchronously shows one request and returns its identifier.
  ///
  /// - Returns: Stable request identifier for manual dismissal.
  /// Enqueues and returns a request identifier for future explicit dismissal.
  ///
  /// - Parameter builder: Builder containing content, style, queue policy, and callbacks.
  /// - Returns: The request identifier.
  public static func showAndReturnID(builder: FKToastBuilder) async -> UUID {
    let id = UUID()
    await MainActor.run {
      _ = FKToastCenter.shared.enqueue(builder: builder, id: id)
    }
    return id
  }

  /// Removes current and pending overlays.
  ///
  /// - Parameter animated: Whether to animate active dismissals.
  public static func clearAll(animated: Bool = true) {
    Task { @MainActor in
      FKToastCenter.shared.clearAll(animated: animated)
    }
  }

  /// Dismisses one request by identifier.
  ///
  /// - Parameters:
  ///   - id: Identifier returned by async APIs.
  ///   - reason: Reason emitted to lifecycle hooks.
  ///   - animated: Whether dismissal should be animated.
  /// Dismisses a specific overlay request.
  ///
  /// - Parameters:
  ///   - id: Target request identifier.
  ///   - reason: Dismiss reason propagated to lifecycle hooks.
  ///   - animated: Whether to animate removal.
  public static func dismiss(_ id: UUID, reason: FKToastDismissReason = .manual, animated: Bool = true) {
    Task { @MainActor in
      FKToastCenter.shared.dismiss(id: id, reason: reason, animated: animated)
    }
  }
}
public enum FKHUD {
  /// Shows an indeterminate loading HUD.
  ///
  /// - Parameters:
  ///   - text: Optional loading message.
  ///   - interceptTouches: Whether the HUD blocks interactions behind it.
  ///   - timeout: Safety timeout to prevent hanging overlays.
  ///
  /// HUD operations are routed through the unified queue, so they stay deterministic under
  /// concurrent calls from multiple features.
  public static func showLoading(
    _ text: String? = nil,
    interceptTouches: Bool = true,
    timeout: TimeInterval? = 25
  ) {
    let message = text ?? "Loading…"
    FKToast.show(
      builder: .init(
        content: .message(message),
        configuration: .init(kind: .hud, style: .loading, duration: 0, timeout: timeout, interceptTouches: interceptTouches)
      )
    )
  }

  /// Shows status feedback as a HUD card.
  ///
  /// - Parameters:
  ///   - title: Primary status text.
  ///   - subtitle: Optional detail line.
  ///   - style: Semantic style (`success`, `error`, `warning`, etc.).
  public static func showStatus(_ title: String, subtitle: String? = nil, style: FKToastStyle = .info) {
    let content: FKToastContent = subtitle.map { .titleSubtitle(title: title, subtitle: $0) } ?? .message(title)
    FKToast.show(builder: .init(content: content, configuration: .init(kind: .hud, style: style, duration: 0, timeout: 20, interceptTouches: true)))
  }

  /// Shows a determinate progress HUD using textual percentage.
  ///
  /// - Parameters:
  ///   - title: Primary progress title.
  ///   - progress: Progress value in range `0...1`.
  ///   - interceptTouches: Whether the HUD blocks touches.
  public static func showProgress(_ title: String, progress: Double, interceptTouches: Bool = true) {
    let clamped = min(max(progress, 0), 1)
    let percent = Int((clamped * 100).rounded())
    FKToast.show(
      builder: .init(
        content: .titleSubtitle(title: title, subtitle: "\(percent)%"),
        configuration: .init(kind: .hud, style: .info, duration: 0, timeout: 20, interceptTouches: interceptTouches)
      )
    )
  }

  /// Shows a success HUD that dismisses automatically.
  ///
  /// - Parameters:
  ///   - text: Message text.
  ///   - duration: Auto-dismiss duration.
  public static func showSuccess(_ text: String, duration: TimeInterval = 1.8) {
    FKToast.show(builder: .init(content: .message(text), configuration: .init(kind: .hud, style: .success, duration: duration, timeout: duration, interceptTouches: false)))
  }

  /// Shows a failure HUD that dismisses automatically.
  ///
  /// - Parameters:
  ///   - text: Message text.
  ///   - duration: Auto-dismiss duration.
  public static func showFailure(_ text: String, duration: TimeInterval = 1.8) {
    FKToast.show(builder: .init(content: .message(text), configuration: .init(kind: .hud, style: .error, duration: duration, timeout: duration, interceptTouches: false)))
  }
}

public enum FKSnackbar {
  /// Shows a snackbar with optional primary and secondary actions.
  ///
  /// - Parameters:
  ///   - text: Visible message.
  ///   - action: Optional primary action.
  ///   - secondaryAction: Optional secondary action (e.g. dismiss).
  ///   - style: Semantic visual style.
  ///   - actionHandler: Closure for primary action.
  ///   - secondaryActionHandler: Closure for secondary action.
  ///
  /// Snackbar defaults to bottom placement and swipe dismissal for expected platform behavior.
  public static func show(
    _ text: String,
    action: FKToastAction? = nil,
    secondaryAction: FKToastAction? = nil,
    style: FKToastStyle = .normal,
    actionHandler: (@MainActor () -> Void)? = nil,
    secondaryActionHandler: (@MainActor () -> Void)? = nil
  ) {
    FKToast.show(
      builder: .init(
        content: .message(text),
        configuration: .init(kind: .snackbar, style: style, position: .bottom, duration: 4, action: action, secondaryAction: secondaryAction),
        actionHandler: actionHandler,
        secondaryActionHandler: secondaryActionHandler
      )
    )
  }
}

#if canImport(SwiftUI)
private extension FKToastBuilder {
  func copy(
    configuration: FKToastConfiguration,
    hooks: FKToastLifecycleHooks,
    actionHandler: (@MainActor () -> Void)?
  ) -> FKToastBuilder {
    FKToastBuilder(
      content: content,
      icon: icon,
      configuration: configuration,
      hooks: hooks,
      actionHandler: actionHandler,
      secondaryActionHandler: secondaryActionHandler
    )
  }
}
#endif
