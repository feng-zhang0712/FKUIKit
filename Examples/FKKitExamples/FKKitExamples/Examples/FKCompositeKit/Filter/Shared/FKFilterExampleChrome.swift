import UIKit
import FKCompositeKit

/// Demo-only helpers on top of ``FKFilterHosting`` (debug logging).
enum FKFilterExampleChrome {
  /// Optional console trace for ``FKFilterController/onSelection``.
  @MainActor
  static func debugPrintSelection(_ ctx: FKFilterSelectionContext<String>) {
    let section = ctx.sectionID.map(\.rawValue) ?? "—"
    print(
      "[FilterExample] onSelection tab=\(ctx.tabID) panel=\(ctx.panelKind.rawValue) section=\(section) title=\(ctx.item.title) id=\(ctx.item.id.rawValue) mode=\(ctx.effectiveSelectionMode)"
    )
  }

  @MainActor
  @discardableResult
  static func embed(
    filterHost: FKFilterController<String>,
    in parent: UIViewController,
    topAnchor: NSLayoutYAxisAnchor,
    overlayHost: UIView,
    logSelection: Bool
  ) -> UIView? {
    let strip = FKFilterHosting.embedStrip(
      filterHost,
      in: parent,
      topAnchor: topAnchor,
      fixedStripHeight: FKFilterExampleAppearance.filterStripChromeHeight,
      overlayHost: overlayHost,
      useCompactTabButtonInsets: true
    )
    if logSelection {
      filterHost.onSelection = { Self.debugPrintSelection($0) }
    }
    return strip
  }

  @MainActor
  static func installBodyPlaceholder(below stripBottom: NSLayoutYAxisAnchor, in parent: UIViewController) {
    FKFilterHosting.installContentBackgroundBelowStrip(in: parent, stripBottom: stripBottom)
  }
}
