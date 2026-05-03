import UIKit

/// Optional emphasis when a badge appears; repeating modes run until hidden or cleared.
public enum FKBadgeAnimation: Equatable, Sendable {
  /// No animation.
  case none
  /// Brief scale-up then settle (default parameters match a subtle “pop”).
  ///
  /// - Parameters:
  ///   - fromScale: Initial scale before spring expansion.
  ///   - overshootScale: Peak scale before settling back to identity.
  ///   - duration: Total animation duration.
  case pop(fromScale: CGFloat = 0.01, overshootScale: CGFloat = 1.12, duration: TimeInterval = 0.28)
  /// Repeating opacity pulse.
  ///
  /// - Parameters:
  ///   - minAlpha: Lower alpha bound.
  ///   - maxAlpha: Upper alpha bound.
  ///   - duration: One-way fade duration.
  case blink(minAlpha: CGFloat = 0.35, maxAlpha: CGFloat = 1.0, duration: TimeInterval = 0.55)
  /// Repeating scale breathing between 1.0 and `scale`.
  ///
  /// - Parameters:
  ///   - scale: Peak scale.
  ///   - duration: One-way scale duration.
  case pulse(scale: CGFloat = 1.12, duration: TimeInterval = 0.7)
}
