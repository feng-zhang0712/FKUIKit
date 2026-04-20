//
// FKSwipeActionAnimator.swift
//
// Animation helper for FKSwipeAction open/close transitions.
//

import UIKit

@MainActor
enum FKSwipeActionAnimator {
  /// Performs spring animation for swipe offset transition.
  ///
  /// This helper centralizes animation options to keep interaction tuning
  /// consistent between open/close and rebound transitions.
  ///
  /// - Parameters:
  ///   - duration: Total animation duration.
  ///   - damping: Spring damping ratio in 0...1.
  ///   - velocity: Initial spring velocity.
  ///   - animations: Animation block applied to UI state.
  ///   - completion: Optional completion callback.
  static func animateOffset(
    duration: TimeInterval,
    damping: CGFloat = 0.9,
    velocity: CGFloat = 0,
    animations: @escaping () -> Void,
    completion: ((Bool) -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: min(max(0.55, damping), 1),
      initialSpringVelocity: max(0, velocity),
      options: [.allowUserInteraction, .curveEaseOut, .beginFromCurrentState],
      animations: animations,
      completion: completion
    )
  }
}
