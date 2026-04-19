//
// FKBadgeAnimation.swift
//

import UIKit

/// Optional emphasis when a badge appears; repeating modes run until hidden or cleared.
public enum FKBadgeAnimation: Equatable, Sendable {
  case none
  /// Brief scale-up then settle (default parameters match a subtle “pop”).
  case pop(fromScale: CGFloat = 0.01, overshootScale: CGFloat = 1.12, duration: TimeInterval = 0.28)
  /// Repeating opacity pulse.
  case blink(minAlpha: CGFloat = 0.35, maxAlpha: CGFloat = 1.0, duration: TimeInterval = 0.55)
  /// Repeating scale breathing between 1.0 and `scale`.
  case pulse(scale: CGFloat = 1.12, duration: TimeInterval = 0.7)
}
