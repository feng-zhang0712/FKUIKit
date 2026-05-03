import Foundation

/// Semantic anchor for pinning the badge to the target (uses leading/trailing for RTL-safe layout).
///
/// - Important: Corner anchors align the target's corner to the badge view's **center**.
///   Use `FKBadgeController.offset` to fine-tune placement.
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
