//
// FKSwipeActionManager.swift
//
// Global coordinator to keep swipe states mutually exclusive.
//

import Foundation

@MainActor
public final class FKSwipeActionManager {
  /// Shared singleton.
  public static let shared = FKSwipeActionManager()

  /// Global switch for all swipe actions.
  public var isGloballyEnabled: Bool = true

  /// Weak registry for all active controllers.
  private var controllers = NSHashTable<FKSwipeActionController>.weakObjects()
  /// Reference to the currently opened controller, if any.
  private weak var openedController: FKSwipeActionController?

  /// Creates the singleton instance.
  private init() {}

  /// Registers one controller in the global weak registry.
  ///
  /// - Parameter controller: Controller attached to a reusable cell.
  func register(controller: FKSwipeActionController) {
    controllers.add(controller)
  }

  /// Unregisters a controller when its host cell is released.
  ///
  /// - Parameter controller: Controller that should be removed from tracking.
  func unregister(controller: FKSwipeActionController) {
    if openedController === controller {
      openedController = nil
    }
    controllers.remove(controller)
  }

  /// Notifies the manager that a controller is about to open.
  ///
  /// - Parameters:
  ///   - controller: Controller requesting open state.
  ///   - exclusive: Whether opening should close all other controllers.
  func notifyWillOpen(_ controller: FKSwipeActionController, exclusive: Bool) {
    guard exclusive else {
      openedController = controller
      return
    }
    for candidate in controllers.allObjects where candidate !== controller {
      candidate.close(animated: true)
    }
    openedController = controller
  }

  /// Clears open-state pointer when a controller closes.
  ///
  /// - Parameter controller: Controller that just transitioned to closed state.
  func notifyDidClose(_ controller: FKSwipeActionController) {
    if openedController === controller {
      openedController = nil
    }
  }

  /// Closes all currently open swipe actions.
  public func closeAll(animated: Bool = true) {
    for controller in controllers.allObjects {
      controller.close(animated: animated)
    }
    openedController = nil
  }
}
