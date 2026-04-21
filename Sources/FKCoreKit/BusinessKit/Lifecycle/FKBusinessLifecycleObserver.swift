import Foundation
import UIKit

/// Default implementation of ``FKBusinessLifecycleObserving`` based on `UIApplication` notifications.
public final class FKBusinessLifecycleObserver: FKBusinessLifecycleObserving, @unchecked Sendable {
  /// Current lifecycle state snapshot.
  public private(set) var state: FKAppLifecycleState {
    get {
      lock.lock()
      let value = _state
      lock.unlock()
      return value
    }
    set {
      lock.lock()
      _state = newValue
      let handlers = observers.values
      lock.unlock()
      handlers.forEach { $0(newValue) }
    }
  }

  /// Lock protecting state and observer dictionary.
  private let lock = NSLock()
  /// Backing storage for lifecycle state.
  private var _state: FKAppLifecycleState = .notRunning
  /// Registered lifecycle observers keyed by token identifier.
  private var observers: [UUID: @Sendable (FKAppLifecycleState) -> Void] = [:]
  /// Notification observer tokens retained for lifecycle monitoring.
  private var notificationTokens: [NSObjectProtocol] = []

  /// Creates lifecycle observer and installs app notification listeners.
  ///
  /// - Parameter center: Notification center used to observe app events.
  public init(center: NotificationCenter = .default) {
    _state = .launching
    install(center: center)
  }

  deinit {
    notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
  }

  /// Adds lifecycle observer and emits current state immediately.
  ///
  /// - Parameter handler: Callback receiving lifecycle state updates.
  /// - Returns: Observation token for cancellation.
  @discardableResult
  public func observe(_ handler: @escaping @Sendable (FKAppLifecycleState) -> Void) -> FKBusinessObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let current = _state
    lock.unlock()

    handler(current)

    return FKBusinessObservationToken { [weak self] in
      guard let self else { return }
      self.lock.lock()
      self.observers[id] = nil
      self.lock.unlock()
    }
  }

  /// Installs `UIApplication` notification observers and maps them to toolkit states.
  ///
  /// - Parameter center: Notification center used for observer registration.
  private func install(center: NotificationCenter) {
    let q = OperationQueue.main

    notificationTokens.append(center.addObserver(
      forName: UIApplication.didFinishLaunchingNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .inactive
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .active
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .inactive
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .background
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .inactive
    })

    notificationTokens.append(center.addObserver(
      forName: UIApplication.willTerminateNotification,
      object: nil,
      queue: q
    ) { [weak self] _ in
      self?.state = .terminated
    })
  }
}

