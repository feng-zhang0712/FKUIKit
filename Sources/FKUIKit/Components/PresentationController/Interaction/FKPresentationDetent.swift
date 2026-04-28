import UIKit

/// Height strategy used by sheet-style presentation modes.
public enum FKPresentationDetent: Equatable {
  /// Uses the intrinsic or preferred content size of the presented controller.
  case fitContent
  /// Uses a fixed height in points.
  case fixed(CGFloat)
  /// Uses a ratio relative to the available container height.
  case fraction(CGFloat)
  /// Expands to the maximum height allowed by the container and safe area rules.
  case full
}
