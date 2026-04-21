import CoreLocation
import Foundation

#if os(iOS)

/// Handles all Core Location permission flows under a unified permission contract.
///
/// This handler supports:
/// - `when in use`
/// - `always`
/// - temporary full-accuracy upgrade on iOS 14+
@MainActor
final class FKLocationPermissionHandler: NSObject, FKPermissionHandling, @preconcurrency CLLocationManagerDelegate {
  /// Target permission kind bound to this handler instance.
  let kind: FKPermissionKind
  /// Cached manager used during interactive authorization requests.
  private var manager: CLLocationManager?
  /// Continuation resumed when an authorization callback is received.
  private var continuation: CheckedContinuation<FKPermissionResult, Never>?

  init(kind: FKPermissionKind) {
    self.kind = kind
  }

  /// Reads current location authorization state without prompting.
  func currentStatus() async -> FKPermissionStatus {
    let status = CLLocationManager.authorizationStatus()
    switch kind {
    case .locationWhenInUse:
      return mapWhenInUse(status)
    case .locationAlways:
      return mapAlways(status)
    case .locationTemporaryFullAccuracy:
      return mapTemporaryAccuracy(status)
    default:
      return .restricted
    }
  }

  /// Requests location authorization according to the configured `kind`.
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult {
    if kind == .locationTemporaryFullAccuracy {
      return await requestTemporaryAccuracy(request)
    }

    let current = await currentStatus()
    if current != .notDetermined {
      return FKPermissionResult(kind: kind, status: current)
    }

    // Keep waiting until Core Location leaves the undecided state.
    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      let manager = CLLocationManager()
      manager.delegate = self
      self.manager = manager
      if self.kind == .locationAlways {
        manager.requestAlwaysAuthorization()
      } else {
        manager.requestWhenInUseAuthorization()
      }
    }
  }

  /// Delegate callback invoked by Core Location when authorization changes.
  ///
  /// The method is nonisolated to satisfy delegate requirements; execution hops back to
  /// the main actor before touching actor-isolated state.
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      guard let continuation = self.continuation else { return }
      let status = self.mapSystemStatus(CLLocationManager.authorizationStatus())
      if status == .notDetermined {
        return
      }
      self.continuation = nil
      self.manager = nil
      continuation.resume(returning: FKPermissionResult(kind: self.kind, status: status))
    }
  }

  /// Requests temporary full-accuracy upgrade after base location permission is granted.
  private func requestTemporaryAccuracy(_ request: FKPermissionRequest) async -> FKPermissionResult {
    guard #available(iOS 14.0, *) else {
      return FKPermissionResult(kind: kind, status: .deviceDisabled, error: .unavailable)
    }

    // Temporary accuracy can only be requested after basic location access is granted.
    let baseStatus = CLLocationManager.authorizationStatus()
    guard baseStatus == .authorizedWhenInUse || baseStatus == .authorizedAlways else {
      return FKPermissionResult(kind: kind, status: .denied)
    }

    // Reuse one manager instance so we can query the latest accuracy authorization.
    let manager = CLLocationManager()
    self.manager = manager

    // Skip request if already at full accuracy.
    if manager.accuracyAuthorization == .fullAccuracy {
      self.manager = nil
      return FKPermissionResult(kind: kind, status: .authorized)
    }

    // A matching key must exist under NSLocationTemporaryUsageDescriptionDictionary.
    let key = request.temporaryLocationPurposeKey ?? "FKLocationTemporaryFullAccuracyPurpose"
    do {
      try await manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: key)
    } catch {
      self.manager = nil
      return FKPermissionResult(kind: kind, status: .denied, error: .custom(error.localizedDescription))
    }

    // Re-check current accuracy after the system request returns.
    let status: FKPermissionStatus = manager.accuracyAuthorization == .fullAccuracy ? .authorized : .denied
    self.manager = nil
    return FKPermissionResult(kind: kind, status: status)
  }

  /// Maps system authorization status to this handler's current permission kind.
  private func mapSystemStatus(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch kind {
    case .locationWhenInUse:
      return mapWhenInUse(status)
    case .locationAlways:
      return mapAlways(status)
    case .locationTemporaryFullAccuracy:
      return mapTemporaryAccuracy(status)
    default:
      return .restricted
    }
  }

  /// Maps Core Location status for `when in use` capability.
  private func mapWhenInUse(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorizedWhenInUse, .authorizedAlways: return .authorized
    @unknown default: return .restricted
    }
  }

  /// Maps Core Location status for `always` capability.
  private func mapAlways(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied, .authorizedWhenInUse: return .denied
    case .authorizedAlways: return .authorized
    @unknown default: return .restricted
    }
  }

  /// Maps temporary full-accuracy capability into unified permission status.
  private func mapTemporaryAccuracy(_ status: CLAuthorizationStatus) -> FKPermissionStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .restricted: return .restricted
    case .denied: return .denied
    case .authorizedWhenInUse, .authorizedAlways:
      if #available(iOS 14.0, *) {
        let accuracy = CLLocationManager().accuracyAuthorization
        return accuracy == .fullAccuracy ? .authorized : .limited
      }
      return .authorized
    @unknown default: return .restricted
    }
  }
}

#endif
