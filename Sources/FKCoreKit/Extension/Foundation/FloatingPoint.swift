import Foundation

public extension FloatingPoint {
  /// Clamps `self` into `[limits.lowerBound, limits.upperBound]`.
  func fk_clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }

  /// Returns `value` if it is finite; otherwise `nil`.
  static func fk_finiteOrNil(_ value: Self) -> Self? {
    value.isFinite ? value : nil
  }
}

public extension BinaryFloatingPoint {
  /// Linear interpolation between `a` and `b` by parameter `t` (not clamped).
  static func fk_lerp(_ a: Self, _ b: Self, t: Self) -> Self {
    a + (b - a) * t
  }
}
