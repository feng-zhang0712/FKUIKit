import Foundation

public extension Comparable {
  /// Clamps `self` into `[limits.lowerBound, limits.upperBound]`.
  func fk_clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }

  /// Clamps `self` into `[low, high]`; when `low > high`, bounds are swapped.
  func fk_clamped(min low: Self, max high: Self) -> Self {
    let lower = Swift.min(low, high)
    let upper = Swift.max(low, high)
    return fk_clamped(to: lower...upper)
  }
}
