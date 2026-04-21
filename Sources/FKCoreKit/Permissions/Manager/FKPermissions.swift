import Foundation

#if os(iOS)
import UIKit

/// Global permission manager for FKCoreKit.
///
/// This type provides a single entry point for checking and requesting iOS permissions with
/// a unified status model and both closure-based and async/await APIs.
@MainActor
public final class FKPermissions: FKPermissionObserving {
  /// Shared singleton for app-wide permission operations.
  public static let shared = FKPermissions()

  private let prePromptPresenter = FKPermissionPrePromptPresenter()
  private var handlers: [FKPermissionKind: FKPermissionHandling] = [:]
  private var observers: [UUID: @Sendable (FKPermissionKind, FKPermissionStatus) -> Void] = [:]
  private var cachedStatuses: [FKPermissionKind: FKPermissionStatus] = [:]
  private nonisolated(unsafe) var appActiveObserver: NSObjectProtocol?

  private init() {
    registerDefaultHandlers()
    registerLifecycleObserver()
  }

  deinit {
    if let appActiveObserver {
      NotificationCenter.default.removeObserver(appActiveObserver)
    }
  }

  /// Reads current status for one permission without triggering any system prompt.
  ///
  /// - Parameter kind: Permission kind to inspect.
  /// - Returns: Current unified permission status.
  public func status(for kind: FKPermissionKind) async -> FKPermissionStatus {
    guard let handler = handlers[kind] else { return .unavailableFallback }
    return await handler.currentStatus()
  }

  /// Closure-based status API.
  ///
  /// - Parameters:
  ///   - kind: Permission kind to inspect.
  ///   - completion: Callback invoked on main actor.
  public func status(for kind: FKPermissionKind, completion: @escaping @Sendable (FKPermissionStatus) -> Void) {
    Task { @MainActor in
      completion(await status(for: kind))
    }
  }

  /// Requests a single permission with optional pre-permission guide.
  ///
  /// - Parameter request: Request model for target permission.
  /// - Returns: Request result containing status and optional error.
  public func request(_ request: FKPermissionRequest) async -> FKPermissionResult {
    guard let handler = handlers[request.kind] else {
      return FKPermissionResult(kind: request.kind, status: .deviceDisabled, error: .unavailable)
    }

    let shouldContinue = await prePromptPresenter.presentIfNeeded(request.prePrompt)
    guard shouldContinue else {
      return FKPermissionResult(kind: request.kind, status: await status(for: request.kind), error: .prePromptCancelled)
    }

    let result = await handler.requestAuthorization(using: request)
    cachedStatuses[request.kind] = result.status
    notifyObserversIfNeeded(for: request.kind, latest: result.status)
    return result
  }

  /// Closure-based request API for a single permission.
  ///
  /// - Parameters:
  ///   - request: Request model for target permission.
  ///   - completion: Callback invoked on main actor with final result.
  public func request(_ request: FKPermissionRequest, completion: @escaping @Sendable (FKPermissionResult) -> Void) {
    Task { @MainActor in
      completion(await self.request(request))
    }
  }

  /// Requests multiple permissions and returns all results when every request completes.
  ///
  /// - Parameter requests: Permission requests to run sequentially on main actor.
  /// - Returns: Result map keyed by permission kind.
  public func request(_ requests: [FKPermissionRequest]) async -> [FKPermissionKind: FKPermissionResult] {
    var output: [FKPermissionKind: FKPermissionResult] = [:]
    for request in requests {
      output[request.kind] = await self.request(request)
    }
    return output
  }

  /// Closure-based batch request API.
  ///
  /// - Parameters:
  ///   - requests: Permission requests to execute.
  ///   - completion: Callback with full result map.
  public func request(
    _ requests: [FKPermissionRequest],
    completion: @escaping @Sendable ([FKPermissionKind: FKPermissionResult]) -> Void
  ) {
    Task { @MainActor in
      completion(await self.request(requests))
    }
  }

  /// Opens this app's settings page in the system Settings app.
  ///
  /// - Returns: `true` when URL can be opened and request is sent.
  @discardableResult
  public func openAppSettings() -> Bool {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      return false
    }
    UIApplication.shared.open(url)
    return true
  }

  /// Registers a callback for runtime status change notifications.
  ///
  /// - Parameter callback: Callback fired when status for a permission changes.
  /// - Returns: Observation token. Keep a strong reference to continue observing.
  public func observeStatusChanges(_ callback: @escaping @Sendable (FKPermissionKind, FKPermissionStatus) -> Void) -> FKPermissionObservationToken {
    let id = UUID()
    observers[id] = callback
    return FKPermissionObservationToken { [weak self] in
      Task { @MainActor in
        self?.observers[id] = nil
      }
    }
  }

  private func registerDefaultHandlers() {
    let allHandlers: [FKPermissionHandling] = [
      FKCameraPermissionHandler(),
      FKPhotoPermissionHandler(kind: .photoLibraryRead),
      FKPhotoPermissionHandler(kind: .photoLibraryAddOnly),
      FKMicrophonePermissionHandler(),
      FKLocationPermissionHandler(kind: .locationWhenInUse),
      FKLocationPermissionHandler(kind: .locationAlways),
      FKLocationPermissionHandler(kind: .locationTemporaryFullAccuracy),
      FKNotificationPermissionHandler(),
      FKBluetoothPermissionHandler(),
      FKEventPermissionHandler(kind: .calendar),
      FKEventPermissionHandler(kind: .reminders),
      FKMediaLibraryPermissionHandler(),
      FKSpeechPermissionHandler(),
      FKAppTrackingPermissionHandler(),
    ]

    allHandlers.forEach { handlers[$0.kind] = $0 }
  }

  private func registerLifecycleObserver() {
    appActiveObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        await self?.refreshAndNotifyChanges()
      }
    }
  }

  private func refreshAndNotifyChanges() async {
    for kind in handlers.keys {
      guard let handler = handlers[kind] else { continue }
      let latest = await handler.currentStatus()
      notifyObserversIfNeeded(for: kind, latest: latest)
    }
  }

  private func notifyObserversIfNeeded(for kind: FKPermissionKind, latest: FKPermissionStatus) {
    let previous = cachedStatuses[kind]
    cachedStatuses[kind] = latest
    guard previous != latest else { return }
    observers.values.forEach { $0(kind, latest) }
  }
}

private extension FKPermissionStatus {
  static let unavailableFallback: FKPermissionStatus = .deviceDisabled
}

#endif
