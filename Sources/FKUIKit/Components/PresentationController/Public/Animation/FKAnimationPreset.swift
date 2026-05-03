import UIKit

/// Built-in transition presets for FK presentation animations.
public enum FKAnimationPreset {
  /// Tries to match native sheet-like motion.
  case systemLike
  /// Uses spring motion with configurable damping/response.
  case spring
  /// Uses a standard ease-in-out timing curve.
  case easeInOut
  /// Uses alpha-only fade transitions.
  case fade
  /// Disables transition animation.
  case none
}

