import UIKit

/// High-level placement mode for a presented controller.
public enum FKPresentationMode {
  /// Presents as a sheet attached to the bottom edge.
  case bottomSheet
  /// Presents as a sheet attached to the top edge.
  case topSheet
  /// Presents as a centered floating panel.
  case center
  /// Presents relative to an anchor specification.
  case anchor(FKAnchor)
  /// Presents from a custom edge for non-standard menu or tray patterns.
  case edge(UIRectEdge)
}
