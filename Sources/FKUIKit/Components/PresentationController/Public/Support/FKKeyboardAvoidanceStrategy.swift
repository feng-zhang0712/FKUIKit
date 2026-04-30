import Foundation

/// Strategy used to avoid keyboard occlusion while presenting content.
public enum FKKeyboardAvoidanceStrategy: Equatable {
  /// Disables keyboard avoidance.
  case disabled
  /// Adjusts the presented container frame (move/resize).
  ///
  /// Best for fixed-layout forms where the whole sheet should shift as keyboard appears.
  case adjustContainer
  /// Adjusts only content insets (best for scroll views).
  ///
  /// Recommended when content is hosted in a scroll view.
  case adjustContentInsets
  /// Tries to follow keyboard interactively (best-effort).
  ///
  /// Useful for chat-like experiences and fast keyboard transitions.
  case interactive
}

