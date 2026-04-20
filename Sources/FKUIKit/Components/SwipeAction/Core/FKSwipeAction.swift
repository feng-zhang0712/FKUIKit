//
// FKSwipeAction.swift
//
// Public namespace and convenience APIs.
//

import UIKit

/// Global namespace for FKSwipeAction.
@MainActor
public enum FKSwipeAction {
  /// Shared default configuration applied when the caller does not pass one.
  ///
  /// Use this property to define a consistent baseline style and behavior
  /// across the whole app, then override per-cell values when needed.
  public static var defaultConfiguration = FKSwipeActionConfiguration()

  /// Closes all opened swipe actions.
  ///
  /// - Parameter animated: Whether close transition should be animated.
  public static func closeAll(animated: Bool = true) {
    FKSwipeActionManager.shared.closeAll(animated: animated)
  }

  /// Enables or disables all swipe interactions globally.
  ///
  /// When set to `false`, all currently opened swipe states are closed
  /// immediately using animation.
  ///
  /// - Parameter enabled: Global interaction switch for all registered cells.
  public static func setGloballyEnabled(_ enabled: Bool) {
    FKSwipeActionManager.shared.isGloballyEnabled = enabled
    if !enabled {
      FKSwipeActionManager.shared.closeAll(animated: true)
    }
  }
}
