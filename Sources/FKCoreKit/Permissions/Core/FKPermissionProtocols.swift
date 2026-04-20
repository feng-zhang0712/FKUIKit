import Foundation

/// Contract for a single permission handler.
@MainActor
public protocol FKPermissionHandling: AnyObject {
  /// The permission kind that this handler serves.
  var kind: FKPermissionKind { get }

  /// Reads current system authorization state without prompting user.
  func currentStatus() async -> FKPermissionStatus

  /// Requests authorization from system API and returns final status.
  ///
  /// - Parameter request: Request context containing optional temporary location purpose key.
  func requestAuthorization(using request: FKPermissionRequest) async -> FKPermissionResult
}

/// Contract for manager-level observing.
@MainActor
public protocol FKPermissionObserving: AnyObject {
  /// Registers a callback for status changes.
  ///
  /// - Parameter callback: Receives changed permission kind and latest status.
  /// - Returns: An observation token. Keep it alive; call `invalidate()` when no longer needed.
  func observeStatusChanges(_ callback: @escaping @Sendable (FKPermissionKind, FKPermissionStatus) -> Void) -> FKPermissionObservationToken
}
