import UIKit
import FKUIKit

/// Common layout steps when placing ``FKFilterController`` under a navigation or safe-area region and pinning dropdown presentation to a larger host (e.g. the screen root).
///
/// Typical pattern: embed the strip, then add a full-width filler view below it for your main content.
public enum FKFilterHosting {
  /// Adds `filter` as a child of `parent`, pins its view under `topAnchor` with a fixed height, optionally tightens ``FKTabBar`` item button insets (see ``useCompactTabButtonInsets``), pins the anchored overlay to `overlayHost`, and returns `filter.view` for further constraints.
  @MainActor
  @discardableResult
  public static func embedStrip<TabID: Hashable>(
    _ filter: FKFilterController<TabID>,
    in parent: UIViewController,
    topAnchor: NSLayoutYAxisAnchor,
    fixedStripHeight: CGFloat,
    overlayHost: UIView,
    useCompactTabButtonInsets: Bool = false,
    compactHorizontalInset: CGFloat = 4,
    compactVerticalInset: CGFloat = 6
  ) -> UIView? {
    parent.addChild(filter)
    filter.loadViewIfNeeded()
    guard let fv = filter.view else { return nil }
    fv.translatesAutoresizingMaskIntoConstraints = false
    parent.view.addSubview(fv)
    NSLayoutConstraint.activate([
      fv.topAnchor.constraint(equalTo: topAnchor),
      fv.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
      fv.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
      fv.heightAnchor.constraint(equalToConstant: fixedStripHeight),
    ])
    filter.didMove(toParent: parent)
    if useCompactTabButtonInsets {
      Self.applyCompactTabButtonInsets(
        to: filter.dropdownController.tabBar,
        horizontalInset: compactHorizontalInset,
        verticalInset: compactVerticalInset
      )
    }
    filter.pinAnchoredPresentationOverlay(to: overlayHost)
    return fv
  }

  /// Fills the area below the filter strip (e.g. table or collection) to the bottom safe area.
  @MainActor
  public static func installContentBackgroundBelowStrip(
    in parent: UIViewController,
    stripBottom: NSLayoutYAxisAnchor,
    backgroundColor: UIColor = .systemBackground,
    bottomAnchor: NSLayoutYAxisAnchor? = nil
  ) {
    let filler = UIView()
    filler.backgroundColor = backgroundColor
    filler.translatesAutoresizingMaskIntoConstraints = false
    parent.view.addSubview(filler)
    let bottom = bottomAnchor ?? parent.view.safeAreaLayoutGuide.bottomAnchor
    NSLayoutConstraint.activate([
      filler.topAnchor.constraint(equalTo: stripBottom),
      filler.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
      filler.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
      filler.bottomAnchor.constraint(equalTo: bottom),
    ])
  }

  /// Tightens ``FKTabBar`` item button insets (matches the demo’s “−4pt per side” chrome).
  @MainActor
  public static func applyCompactTabButtonInsets(
    to tabBar: FKTabBar,
    horizontalInset: CGFloat = 4,
    verticalInset: CGFloat = 6
  ) {
    tabBar.itemButtonConfigurator = { button, _, _ in
      let appearance = FKButtonAppearance(
        backgroundColor: .clear,
        contentInsets: .init(
          top: verticalInset,
          leading: horizontalInset,
          bottom: verticalInset,
          trailing: horizontalInset
        )
      )
      button.setAppearance(appearance, for: .normal)
      button.setAppearance(appearance, for: .selected)
      button.setAppearance(appearance, for: .disabled)
    }
  }
}
