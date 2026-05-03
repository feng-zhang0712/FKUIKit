import UIKit
import FKUIKit

extension FKAnchoredDropdownController {
  /// Resolves ``FKAnchoredDropdownConfiguration/anchorOverride`` into a concrete `FKAnchorConfiguration`.
  func makePresentationAnchorConfiguration() -> FKAnchorConfiguration {
    let sourceView = resolvedAnchorSourceView()
    let hostView = resolvedOverlayHostView()
    let override = configuration.anchorOverride

    let edge = override?.attachmentEdge ?? .bottom
    let direction = override?.expansionDirection ?? .down
    let alignment = override?.horizontalAlignment ?? .fill
    let widthPolicy = override?.widthPolicy ?? .matchContainer
    let offset = override?.attachmentOffset ?? 0

    return FKAnchorConfiguration(
      anchor: FKAnchor(
        sourceView: sourceView,
        edge: edge,
        direction: direction,
        alignment: alignment,
        widthPolicy: widthPolicy,
        offset: offset
      ),
      hostStrategy: .inProvidedContainer(FKWeakReference(hostView)),
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .belowAnchorOnly
    )
  }

  private func resolvedAnchorSourceView() -> UIView {
    if let source = configuration.anchorOverride?.sourceView {
      return source
    }
    return tabBarHost.tabBar
  }

  private func resolvedOverlayHostView() -> UIView {
    if let host = configuration.anchorOverride?.overlayHostView {
      return host
    }
    return tabBarHost.view
  }
}
