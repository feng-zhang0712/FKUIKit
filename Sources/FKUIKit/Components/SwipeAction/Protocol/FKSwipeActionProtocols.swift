//
// FKSwipeActionProtocols.swift
//
// Protocol abstractions for FKSwipeAction.
//

import UIKit

/// Receives lifecycle callbacks from `FKSwipeActionController`.
@MainActor
public protocol FKSwipeActionControllerDelegate: AnyObject {
  /// Called when swipe state changes.
  ///
  /// - Parameters:
  ///   - controller: Controller that changed state.
  ///   - isOpen: Whether the action area is currently open.
  func swipeActionController(_ controller: FKSwipeActionController, didChangeOpenState isOpen: Bool)
}

public extension FKSwipeActionControllerDelegate {
  /// Optional default empty implementation.
  ///
  /// - Parameters:
  ///   - controller: Controller that emitted the state change callback.
  ///   - isOpen: Boolean flag indicating whether the swipe panel is open.
  func swipeActionController(_ controller: FKSwipeActionController, didChangeOpenState isOpen: Bool) {}
}

/// Describes a host that can provide swipe action configuration dynamically.
@MainActor
public protocol FKSwipeActionConfigurable: AnyObject {
  /// Returns configuration for current state.
  ///
  /// Implement this protocol in reusable list hosts when swipe buttons
  /// should be derived from dynamic business state.
  ///
  /// - Returns: A fully resolved per-cell swipe configuration.
  func swipeActionConfiguration() -> FKSwipeActionConfiguration
}
