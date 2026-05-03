import UIKit
import FKUIKit

/// Holds weak references and geometry for a **custom** anchored presentation.
///
/// Assign an instance to `FKAnchoredDropdownConfiguration.anchorOverride`, or call
/// `FKAnchoredDropdownController.setCustomAnchor(source:overlayHost:)`, when the dropdown should
/// attach to a view other than the embedded tab bar.
///
/// - Important: Keep the override object alive while it is referenced from `FKAnchoredDropdownConfiguration`.
///   The configuration struct only holds a reference to this object; it is not retained elsewhere.
@MainActor
public final class FKAnchoredDropdownAnchorOverride {
  /// View that defines the attachment rect (typically the bottom edge for a downward panel).
  ///
  /// When `nil`, the component falls back to the tab bar as the anchor source.
  public weak var sourceView: UIView?

  /// View that hosts the embedded presentation and dimmed mask (``FKAnchorConfiguration/HostStrategy/inProvidedContainer(_:)``).
  ///
  /// Choose a container that is an ancestor of ``sourceView`` (or the same view) so coordinates and
  /// z-ordering stay consistent. When `nil`, the tab bar host’s root view is used.
  public weak var overlayHostView: UIView?

  /// Edge of ``sourceView`` used as the attachment line. Defaults to `.bottom` (panel opens downward).
  public var attachmentEdge: FKAnchor.Edge

  /// Expansion direction relative to ``attachmentEdge``.
  public var expansionDirection: FKAnchor.Direction

  /// Horizontal alignment of the presented panel relative to the anchor.
  public var horizontalAlignment: FKAnchor.Alignment

  /// Width sizing policy for the presented content.
  public var widthPolicy: FKAnchor.WidthPolicy

  /// Visual gap between the anchor edge and the presented content.
  public var attachmentOffset: CGFloat

  /// Creates an override with geometry defaults matching the built-in tab bar anchor behavior.
  public init(
    sourceView: UIView? = nil,
    overlayHostView: UIView? = nil,
    attachmentEdge: FKAnchor.Edge = .bottom,
    expansionDirection: FKAnchor.Direction = .down,
    horizontalAlignment: FKAnchor.Alignment = .fill,
    widthPolicy: FKAnchor.WidthPolicy = .matchContainer,
    attachmentOffset: CGFloat = 0
  ) {
    self.sourceView = sourceView
    self.overlayHostView = overlayHostView
    self.attachmentEdge = attachmentEdge
    self.expansionDirection = expansionDirection
    self.horizontalAlignment = horizontalAlignment
    self.widthPolicy = widthPolicy
    self.attachmentOffset = attachmentOffset
  }
}
