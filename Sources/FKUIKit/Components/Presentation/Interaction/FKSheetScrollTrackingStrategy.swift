import UIKit

/// Strategy used to resolve which scroll view participates in sheet gesture handoff.
public enum FKSheetScrollTrackingStrategy {
  /// Automatically finds the first scroll view in the presented hierarchy.
  ///
  /// Best default when content tree is simple and has one primary scroller.
  case automatic
  /// Disables scroll tracking and always lets the sheet pan handle gestures.
  ///
  /// Use when content is non-scrollable or custom gesture arbitration is handled externally.
  case disabled
  /// Uses an explicitly provided scroll view.
  ///
  /// Recommended when multiple scroll views exist and you need deterministic handoff.
  case explicit(FKWeakReference<UIScrollView>)
}

