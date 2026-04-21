import Foundation

/// Semantic corner for pinning the badge to the target (uses leading/trailing for RTL-safe layout).
/// Uses `leading` / `trailing` so the attachment follows RTL layout.
public enum FKBadgeAnchor: Sendable, Equatable {
  /// Top + leading (often “top-left” in LTR).
  case topLeading
  /// Top + trailing (often “top-right” in LTR).
  case topTrailing
  /// Bottom + leading.
  case bottomLeading
  /// Bottom + trailing.
  case bottomTrailing
  /// Center of the target view.
  case center
}
