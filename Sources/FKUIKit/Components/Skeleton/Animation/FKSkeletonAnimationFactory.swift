//
// FKSkeletonAnimationFactory.swift
//

import QuartzCore

/// Factory for skeleton animations to keep animation creation testable and reusable.
enum FKSkeletonAnimationFactory {
  static func shimmer(duration: CFTimeInterval) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "locations")
    animation.fromValue = [-1.0, -0.5, 0.0]
    animation.toValue = [1.0, 1.5, 2.0]
    animation.duration = duration
    animation.repeatCount = .infinity
    animation.isRemovedOnCompletion = false
    return animation
  }

  static func pulse(duration: CFTimeInterval, minOpacity: Float) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = minOpacity
    animation.toValue = 1.0
    animation.duration = max(0.15, duration / 2)
    animation.autoreverses = true
    animation.repeatCount = .infinity
    animation.isRemovedOnCompletion = false
    return animation
  }
}
