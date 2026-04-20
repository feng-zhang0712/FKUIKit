//
// FKExpandableTextProtocols.swift
//
// Protocol abstractions for state cache and event callbacks.
//

import UIKit

/// State cache contract for expandable text instances.
@MainActor
public protocol FKExpandableTextStateCaching: AnyObject {
  /// Returns the cached display state for identifier.
  ///
  /// - Parameter identifier: Stable cache key for one content entity.
  /// - Returns: Cached state, or `nil` when no record exists.
  func state(for identifier: String) -> FKExpandableTextDisplayState?
  /// Stores the display state for identifier.
  ///
  /// - Parameters:
  ///   - state: State value to store.
  ///   - identifier: Stable cache key.
  func setState(_ state: FKExpandableTextDisplayState, for identifier: String)
  /// Removes cached state for identifier.
  ///
  /// - Parameter identifier: Cache key that should be removed.
  func removeState(for identifier: String)
}

/// Height measurement contract for pre-calculation scenarios.
@MainActor
public protocol FKExpandableTextHeightMeasuring: AnyObject {
  /// Returns measured height for current text payload.
  ///
  /// - Parameters:
  ///   - width: Available layout width for the component.
  ///   - state: Target display state used for measurement.
  /// - Returns: Measured height that includes text, button, and insets.
  func measuredHeight(for width: CGFloat, state: FKExpandableTextDisplayState) -> CGFloat
}
