import UIKit

@MainActor
enum FKTabBarIndicatorFrameCalculator {
  // MARK: - Indicator

  /// Calculates the indicator frame within the tab bar's indicator container.
  ///
  /// Inputs are expressed in the indicator container's coordinate system:
  /// - `itemFrame`: the full cell frame for the relevant item
  /// - `contentFrame`: a tighter frame representing the rendered content (text/icon/custom view)
  ///
  /// This function is intentionally pure and synchronous so it can be used from scroll/drag paths
  /// without allocations or side effects.
  static func frame(
    style: FKTabBarIndicatorStyle,
    itemFrame: CGRect,
    contentFrame: CGRect,
    containerBounds: CGRect,
    customResolver: ((_ itemFrame: CGRect, _ containerBounds: CGRect) -> CGRect)?
  ) -> CGRect {
    if let customResolver {
      // Custom resolver lets hosts override geometry for advanced visuals (e.g. asymmetric shapes).
      // The resolver receives stable coordinate inputs so it remains valid under rotation/RTL.
      return customResolver(itemFrame, containerBounds)
    }

    switch style {
    case .none:
      return .zero
    case .line(let config):
      let base: CGRect
      switch config.followMode {
      case .trackSelectedFrame, .trackContentProgress, .lockedUntilSettle, .custom:
        // Progress interpolation (when applicable) happens in `FKTabBar.updateIndicatorFrame`.
        // Here we only choose between "full item" and "content" anchoring.
        base = itemFrame
      case .trackContentFrame:
        base = contentFrame
      }
      let width = max(0, base.width - config.leadingInset - config.trailingInset)
      let x = base.minX + config.leadingInset
      let y: CGFloat
      switch config.position {
      case .top: y = base.minY
      case .bottom: y = base.maxY - config.thickness
      case .center: y = base.midY - config.thickness * 0.5
      }
      return CGRect(x: x, y: y, width: width, height: config.thickness)
    case .backgroundHighlight(let config), .gradientHighlight(let config), .pill(let config):
      return itemFrame.inset(by: UIEdgeInsets(top: config.insets.top, left: config.insets.leading, bottom: config.insets.bottom, right: config.insets.trailing))
    case .custom:
      return itemFrame
    }
  }
}
