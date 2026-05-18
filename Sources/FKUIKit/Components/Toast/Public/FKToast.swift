import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Strongly typed reference to one enqueued overlay; safe to pass across concurrency domains (`Sendable`).
public final class FKToastHandle: @unchecked Sendable {
  /// Stable identifier shared with `FKToast.dismiss(_:)` and lifecycle hooks.
  public let id: UUID

  init(id: UUID) {
    self.id = id
  }

  /// Dismisses this request if it is visible or still queued. Marshals to the main actor internally.
  public func dismiss(reason: FKToastDismissReason = .manual, animated: Bool = true) {
    FKToast.dismiss(id, reason: reason, animated: animated)
  }

  /// Replaces visible content (and optionally configuration) without re-queuing.
  public func update(content: FKToastContent, configuration: FKToastConfiguration? = nil) async -> Bool {
    await FKToast.update(id, content: content, configuration: configuration)
  }

  /// Updates a visible HUD-style title + percentage subtitle derived from `0...1` progress.
  public func updateProgress(_ progress: Double, title: String? = nil) async -> Bool {
    await FKToast.updateProgress(id, progress: progress, title: title)
  }
}

// MARK: - Toast

/// Global entry for transient banners (`toast`), centered HUDs (`hud`), and bottom snackbars (`snackbar`).
public enum FKToast {
  /// Baseline merged into each request unless overridden per `FKToastConfiguration`.
  @MainActor
  public static var defaultConfiguration: FKToastConfiguration {
    get { FKToastCenter.shared.defaultConfiguration }
    set { FKToastCenter.shared.defaultConfiguration = newValue }
  }

  /// `true` if at least one overlay is attached to a window (queued-only items do not count).
  @MainActor
  public static var isPresenting: Bool {
    FKToastCenter.shared.isPresenting
  }

  /// Presents a string using `FKToastConfiguration` defaults for the given `kind` and semantic `style`.
  public static func show(
    _ message: String,
    style: FKToastStyle = .normal,
    kind: FKToastKind = .toast,
    presentationStrategy: FKToastPresentationStrategy = .sequential
  ) {
    var configuration = FKToastConfiguration(kind: kind, style: style)
    configuration.queue.presentationStrategy = presentationStrategy
    show(
      builder: .init(
        content: .message(message),
        configuration: configuration
      )
    )
  }

  /// Presents or updates a toast bound to `handle`, reusing the same overlay when possible.
  @MainActor
  @discardableResult
  public static func showOrUpdate(
    _ message: String,
    handle: FKToastHandle? = nil,
    style: FKToastStyle = .normal,
    kind: FKToastKind = .toast,
    presentationStrategy: FKToastPresentationStrategy = .replaceActive
  ) -> FKToastHandle {
    var configuration = FKToastConfiguration(kind: kind, style: style)
    configuration.queue.presentationStrategy = presentationStrategy
    if let handle, update(handle.id, content: .message(message), configuration: configuration) {
      return handle
    }
    let id = FKToastCenter.shared.enqueue(
      builder: .init(content: .message(message), configuration: configuration)
    )
    return FKToastHandle(id: id)
  }

  /// Full control: icon override, configuration, lifecycle hooks, and primary action handler.
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

  /// Embeds a caller-built `UIView` (no built-in text stack).
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
  /// Hosts SwiftUI content in a `UIHostingController` (must run on the main actor).
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

  /// Advanced enqueue; runs synchronously on the main thread when already on the main actor.
  public static func show(builder: FKToastBuilder) {
    runOnMainActor {
      _ = FKToastCenter.shared.enqueue(builder: builder)
    }
  }

  private static func runOnMainActor(_ work: @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
      MainActor.assumeIsolated(work)
    } else {
      Task { @MainActor in work() }
    }
  }

  /// Enqueues using a caller-supplied `id` (for correlating with your own models) and returns the active id.
  public static func showReturningID(builder: FKToastBuilder) async -> UUID {
    await MainActor.run {
      FKToastCenter.shared.enqueue(builder: builder, id: UUID())
    }
  }

  /// Convenience around `showReturningID` returning a `FKToastHandle`.
  public static func showReturningHandle(builder: FKToastBuilder) async -> FKToastHandle {
    let id = await showReturningID(builder: builder)
    return FKToastHandle(id: id)
  }

  /// Dismisses every visible overlay and clears the wait queue.
  public static func clearAll(animated: Bool = true) {
    Task { @MainActor in
      FKToastCenter.shared.clearAll(animated: animated)
    }
  }

  /// Dismisses one overlay by id (no-op if unknown).
  public static func dismiss(_ id: UUID, reason: FKToastDismissReason = .manual, animated: Bool = true) {
    Task { @MainActor in
      FKToastCenter.shared.dismiss(id: id, reason: reason, animated: animated)
    }
  }

  /// In-place content refresh for a visible instance.
  @MainActor
  @discardableResult
  public static func update(
    _ id: UUID,
    content: FKToastContent,
    configuration: FKToastConfiguration? = nil
  ) -> Bool {
    FKToastCenter.shared.update(id: id, content: content, configuration: configuration)
  }

  /// Progress helper built on `titleSubtitle` content.
  public static func updateProgress(
    _ id: UUID,
    progress: Double,
    title: String? = nil
  ) async -> Bool {
    await MainActor.run {
      FKToastCenter.shared.updateProgress(id: id, progress: progress, title: title)
    }
  }
}

// MARK: - HUD

/// Opinionated HUD shortcuts on top of `FKToast` (blocking spinners, status, short success/failure).
public enum FKHUD {
  public static func showLoading(
    _ text: String? = nil,
    interceptTouches: Bool = true,
    timeout: TimeInterval? = 25
  ) {
    let message = text ?? FKToastLocalizedText().loadingText
    FKToast.show(
      builder: .init(
        content: .message(message),
        configuration: .init(kind: .hud, style: .loading, duration: 0, timeout: timeout, interceptTouches: interceptTouches)
      )
    )
  }

  public static func showStatus(_ title: String, subtitle: String? = nil, style: FKToastStyle = .info) {
    let content: FKToastContent = subtitle.map { .titleSubtitle(title: title, subtitle: $0) } ?? .message(title)
    FKToast.show(builder: .init(content: content, configuration: .init(kind: .hud, style: style, duration: 0, timeout: 20, interceptTouches: true)))
  }

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

  public static func showSuccess(_ text: String, duration: TimeInterval = 1.8) {
    FKToast.show(builder: .init(content: .message(text), configuration: .init(kind: .hud, style: .success, duration: duration, timeout: duration, interceptTouches: false)))
  }

  public static func showFailure(_ text: String, duration: TimeInterval = 1.8) {
    FKToast.show(builder: .init(content: .message(text), configuration: .init(kind: .hud, style: .error, duration: duration, timeout: duration, interceptTouches: false)))
  }
}

// MARK: - Snackbar

/// Bottom snackbar preset: `.snackbar`, bottom placement, default duration, optional actions.
public enum FKSnackbar {
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
