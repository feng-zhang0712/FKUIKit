import UIKit

/// Height strategy used by sheet-style presentation modes.
public enum FKPresentationDetent: Equatable {
  /// Uses the intrinsic or preferred content size of the presented controller.
  case fitContent
  /// Uses a fixed height in points.
  case fixed(CGFloat)
  /// Uses a ratio relative to the available container height.
  case fraction(CGFloat)
  /// Uses a system-sheet-like medium height (about half of the available container height).
  case medium
  /// Uses a near-full height while preserving a visible edge gap (system-sheet-like large state).
  case large
  /// Expands to the maximum height allowed by the container and safe area rules.
  case full
}
