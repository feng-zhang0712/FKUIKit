import UIKit
import FKUIKit

public extension FKAnchoredDropdownController {
  /// Attaches the dropdown to an arbitrary view on the next (and subsequent) presentations.
  ///
  /// - Parameters:
  ///   - source: View whose bounds define where the sheet attaches (see ``FKAnchoredDropdownAnchorOverride/sourceView``).
  ///   - overlayHost: Container for the embedded presentation and mask. Pass `nil` to use the tab bar host’s root view.
  ///
  /// - Note: Mutating only the weak references on an existing override does not trigger ``configuration``’s `didSet`.
  ///   This method writes through ``FKAnchoredDropdownConfiguration/anchorOverride`` when needed so the override object exists.
  func setCustomAnchor(source: UIView, overlayHost: UIView? = nil) {
    if configuration.anchorOverride == nil {
      var next = configuration
      next.anchorOverride = FKAnchoredDropdownAnchorOverride()
      configuration = next
    }
    configuration.anchorOverride?.sourceView = source
    configuration.anchorOverride?.overlayHostView = overlayHost
  }

  /// Updates geometry for the current ``FKAnchoredDropdownConfiguration/anchorOverride`` without replacing the whole configuration.
  ///
  /// Does nothing when no override is installed; call ``setCustomAnchor(source:overlayHost:)`` first.
  func setAnchorGeometry(
    attachmentEdge: FKAnchor.Edge? = nil,
    expansionDirection: FKAnchor.Direction? = nil,
    horizontalAlignment: FKAnchor.Alignment? = nil,
    widthPolicy: FKAnchor.WidthPolicy? = nil,
    attachmentOffset: CGFloat? = nil
  ) {
    guard let override = configuration.anchorOverride else { return }
    if let attachmentEdge { override.attachmentEdge = attachmentEdge }
    if let expansionDirection { override.expansionDirection = expansionDirection }
    if let horizontalAlignment { override.horizontalAlignment = horizontalAlignment }
    if let widthPolicy { override.widthPolicy = widthPolicy }
    if let attachmentOffset { override.attachmentOffset = attachmentOffset }
  }

  /// Restores the default anchor (tab bar source, tab bar host overlay container) and clears any override object.
  func resetAnchorToTabBarDefault() {
    guard configuration.anchorOverride != nil else { return }
    var next = configuration
    next.anchorOverride = nil
    configuration = next
  }
}
