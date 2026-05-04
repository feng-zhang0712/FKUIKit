import UIKit
import FKCompositeKit

/// Shared layout + debug hooks for Filter example view controllers.
enum FKFilterExampleChrome {
  /// Optional console trace for ``FKFilterController/onSelection``.
  @MainActor
  static func debugPrintSelection(_ ctx: FKFilterSelectionContext<String>) {
    let section = ctx.sectionID.map(\.rawValue) ?? "—"
    print(
      "[FilterExample] onSelection tab=\(ctx.tabID) panel=\(ctx.panelKind.rawValue) section=\(section) title=\(ctx.item.title) id=\(ctx.item.id.rawValue) mode=\(ctx.effectiveSelectionMode)"
    )
  }

  /// Embeds the filter strip host, pins the dropdown overlay, applies tab button insets, and wires optional selection logging.
  @MainActor
  @discardableResult
  static func embed(
    filterHost: FKFilterController<String>,
    in parent: UIViewController,
    topAnchor: NSLayoutYAxisAnchor,
    overlayHost: UIView,
    logSelection: Bool
  ) -> UIView? {
    parent.addChild(filterHost)
    filterHost.loadViewIfNeeded()
    guard let fv = filterHost.view else { return nil }
    fv.translatesAutoresizingMaskIntoConstraints = false
    parent.view.addSubview(fv)
    NSLayoutConstraint.activate([
      fv.topAnchor.constraint(equalTo: topAnchor),
      fv.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
      fv.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
      fv.heightAnchor.constraint(equalToConstant: FKFilterExampleAppearance.filterStripChromeHeight),
    ])
    filterHost.didMove(toParent: parent)
    FKFilterExampleAppearance.applyFilterExampleTabButtonContentInsets(to: filterHost.dropdownController.tabBar)
    filterHost.pinAnchoredPresentationOverlay(to: overlayHost)
    if logSelection {
      filterHost.onSelection = { Self.debugPrintSelection($0) }
    }
    return fv
  }

  /// Fills the area below the filter strip (empty body placeholder).
  @MainActor
  static func installBodyPlaceholder(below stripBottom: NSLayoutYAxisAnchor, in parent: UIViewController) {
    let filler = UIView()
    filler.backgroundColor = .systemBackground
    filler.translatesAutoresizingMaskIntoConstraints = false
    parent.view.addSubview(filler)
    NSLayoutConstraint.activate([
      filler.topAnchor.constraint(equalTo: stripBottom),
      filler.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
      filler.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
      filler.bottomAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }
}
