//
// FKLoadingAnimatorState.swift
//

import Foundation

/// Lifecycle state for `FKLoadingAnimatorView`.
public enum FKLoadingAnimatorState: Equatable {
  /// Animation is actively rendering.
  case loading

  /// Animation has been stopped and cleaned up.
  case stopped

  /// Animation is paused but keeps presentation state.
  case paused
}
