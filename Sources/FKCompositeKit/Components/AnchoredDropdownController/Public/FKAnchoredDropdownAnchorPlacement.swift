import UIKit
import FKUIKit

/// Weak-backed anchor geometry for presentations that attach to a view other than the tab bar.
///
/// Store a reference on ``FKAnchoredDropdownConfiguration/anchorPlacement`` or call
/// ``FKAnchoredDropdownController/setAnchor(source:overlayHost:)``.
///
/// - Important: Retain this object for as long as it is stored in ``FKAnchoredDropdownConfiguration``;
///   the configuration struct only holds a reference to the instance.
@MainActor
public final class FKAnchoredDropdownAnchorPlacement {
  /// View whose bounds define the attachment edge (commonly the bottom for a downward panel).
  ///
  /// When `nil`, the component uses ``FKAnchoredDropdownTabBarHost/tabBar``.
  public weak var sourceView: UIView?

  /// View that hosts the dimmed mask and presented panel (``FKAnchorConfiguration/HostStrategy/inProvidedContainer(_:)``).
  ///
  /// Prefer an ancestor of ``sourceView`` (or the same view). When `nil`, the tab bar host’s root view is used.
  public weak var overlayHostView: UIView?

  /// Edge of ``sourceView`` used as the attachment line. Defaults to `.bottom`.
  public var attachmentEdge: FKAnchor.Edge

  /// Expansion direction relative to ``attachmentEdge``.
  public var expansionDirection: FKAnchor.Direction

  /// Horizontal alignment of the panel relative to the anchor.
  public var horizontalAlignment: FKAnchor.Alignment

  /// Width policy for presented content.
  public var widthPolicy: FKAnchor.WidthPolicy

  /// Offset along the attachment axis between the anchor edge and the panel.
  public var attachmentOffset: CGFloat

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
