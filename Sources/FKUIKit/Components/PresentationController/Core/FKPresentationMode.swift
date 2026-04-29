import UIKit

/// High-level placement mode for a presented controller.
public enum FKPresentationMode {
  /// Presents as a sheet attached to the bottom edge.
  case bottomSheet
  /// Presents as a sheet attached to the top edge.
  case topSheet
  /// Presents as a centered floating panel.
  case center
  /// Presents relative to an anchor and hosts the presentation inside the anchor's hierarchy.
  ///
  /// Use this when you want the overlay to look visually attached to the anchor (e.g. a navigation bar menu),
  /// while keeping the anchor itself above the overlay and optionally limiting the mask to only the area below
  /// the anchor line.
  ///
  case anchor(FKAnchorConfiguration)
  /// Presents from a custom edge for non-standard menu or tray patterns.
  case edge(UIRectEdge)
}
