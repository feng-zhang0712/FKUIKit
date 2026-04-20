//
// UIView+FKTextFieldShake.swift
//
// Lightweight shake animation for validation feedback.
//

import UIKit

/// Animation utilities for FKTextField and related inputs.
///
/// This extension keeps the animation dependency-free and reusable across `UITextField`,
/// `UITextView`, and any container view.
public extension UIView {
  /// Performs a horizontal shake animation.
  ///
  /// - Parameters:
  ///   - amplitude: Translation amplitude in points.
  ///   - shakes: Number of back-and-forth shakes.
  ///   - duration: Total animation duration.
  ///
  /// This method is intended for validation feedback (e.g. invalid input).
  @MainActor
  func fk_shake(
    amplitude: CGFloat = 10,
    shakes: Int = 4,
    duration: TimeInterval = 0.35
  ) {
    guard amplitude > 0, shakes > 0, duration > 0 else { return }
    // Use a keyframe animation to avoid layout changes and keep it GPU-friendly.
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.duration = duration

    // Generate a decaying oscillation sequence: 0 → +a → -a → ... → 0.
    let steps = shakes * 2 + 1
    var values: [CGFloat] = []
    values.reserveCapacity(steps)
    values.append(0)
    for i in 0..<(steps - 1) {
      let direction: CGFloat = (i % 2 == 0) ? 1 : -1
      // Gradually reduce amplitude so the shake feels natural.
      let decay = max(0.4, 1.0 - (CGFloat(i) / CGFloat(max(1, steps - 1))))
      values.append(direction * amplitude * decay)
    }
    animation.values = values
    // Use a stable key so repeated shakes replace the current animation.
    layer.add(animation, forKey: "fk.textfield.shake")
  }
}

