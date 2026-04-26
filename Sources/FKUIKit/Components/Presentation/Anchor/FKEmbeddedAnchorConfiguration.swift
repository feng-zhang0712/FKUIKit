import UIKit

/// Configuration for `FKPresentationMode.anchorEmbedded(_:)`.
///
/// Embedded anchor presentations are hosted inside an existing view hierarchy (instead of a modal
/// `UIPresentationController` container). This enables "menu-like" overlays that appear attached
/// to a navigation bar, toolbar, or any in-page anchor view, while keeping the anchor visually above
/// the overlay (optional) and limiting the mask coverage (optional).
///
/// This mode is intended to replace ad-hoc dropdown implementations with a consistent, reusable API
/// while remaining resilient to layout changes (rotation, safe area changes, trait changes, and dynamic
/// anchor movement).
public struct FKEmbeddedAnchorConfiguration {
  /// Anchor geometry and expansion direction.
  ///
  /// This reuses `FKAnchor` so the mental model stays consistent across `.anchor` and `.anchorEmbedded`.
  public var anchor: FKAnchor

  /// Where the embedded overlay is inserted.
  public var hostStrategy: HostStrategy

  /// Policy controlling the overlay's z-order relative to the anchor.
  public var zOrderPolicy: ZOrderPolicy

  /// Policy controlling how much of the host is covered by the interaction mask.
  public var maskCoveragePolicy: MaskCoveragePolicy

  /// Reposition behavior when host or anchor geometry changes.
  public var repositionPolicy: RepositionPolicy

  /// Creates an embedded anchor configuration.
  public init(
    anchor: FKAnchor,
    hostStrategy: HostStrategy = .inSameSuperviewBelowAnchor,
    zOrderPolicy: ZOrderPolicy = .keepAnchorAbovePresentation,
    maskCoveragePolicy: MaskCoveragePolicy = .belowAnchorOnly,
    repositionPolicy: RepositionPolicy = .init()
  ) {
    self.anchor = anchor
    self.hostStrategy = hostStrategy
    self.zOrderPolicy = zOrderPolicy
    self.maskCoveragePolicy = maskCoveragePolicy
    self.repositionPolicy = repositionPolicy
  }
}

public extension FKEmbeddedAnchorConfiguration {
  /// Strategy used to decide where to host the embedded overlay.
  enum HostStrategy {
    /// Inserts the overlay into the anchor's host view and keeps it below the anchor's direct child view.
    ///
    /// This matches the typical "dropdown attached to a navigation bar / toolbar" layering strategy:
    /// the anchor stays above, and the overlay is visually attached to the anchor edge.
    case inSameSuperviewBelowAnchor

    /// Inserts the overlay into a provided container view.
    ///
    /// Use this for complex hierarchies where the correct host is known in advance.
    case inProvidedContainer(FKWeakReference<UIView>)

    /// Inserts the overlay into a window-level container.
    ///
    /// This is useful when your anchor participates in complex transitions and you want a stable host.
    /// If no suitable window can be resolved at runtime, FK will fall back to the best-effort host.
    case inWindowLevel
  }

  /// Controls whether FK keeps the anchor above the embedded overlay.
  enum ZOrderPolicy {
    /// Ensures the anchor (or its direct host child) stays above the embedded overlay.
    ///
    /// This is the recommended default for "embedded" dropdown menus.
    case keepAnchorAbovePresentation

    /// No special z-order handling.
    case normal
  }

  /// Controls how much of the host area is covered by the interaction mask.
  enum MaskCoveragePolicy {
    /// Only covers the area *below* the anchor attachment line.
    ///
    /// This matches the legacy `FKPresentation` behavior and reduces accidental blocking of UI
    /// above the anchor (e.g. navigation bar items).
    case belowAnchorOnly

    /// Covers the full host bounds.
    case fullScreen
  }

  /// Reposition policy for embedded overlays.
  struct RepositionPolicy {
    /// Whether to listen to host layout changes.
    public var listensToLayoutChanges: Bool
    /// Whether to listen to trait collection changes.
    public var listensToTraitChanges: Bool
    /// Whether to listen to orientation changes.
    public var listensToOrientationChanges: Bool
    /// Debounce interval used to coalesce frequent changes.
    public var debounceInterval: TimeInterval

    public init(
      listensToLayoutChanges: Bool = true,
      listensToTraitChanges: Bool = true,
      listensToOrientationChanges: Bool = true,
      debounceInterval: TimeInterval = 0
    ) {
      self.listensToLayoutChanges = listensToLayoutChanges
      self.listensToTraitChanges = listensToTraitChanges
      self.listensToOrientationChanges = listensToOrientationChanges
      self.debounceInterval = max(0, debounceInterval)
    }
  }
}
