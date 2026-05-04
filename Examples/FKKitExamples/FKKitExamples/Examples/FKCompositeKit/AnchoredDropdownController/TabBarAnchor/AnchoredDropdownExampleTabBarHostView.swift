import UIKit
import FKCompositeKit
import FKUIKit

/// Shared chrome for anchored-dropdown examples: **one** top bar (`FKTabBar` + divider).
///
/// - **Tab-bar anchor demo**: uses the default anchor (``FKTabBar``).
/// - **Custom-anchor demo**: calls ``FKAnchoredDropdownController/setAnchor(source:overlayHost:)`` on a separate control.
///   wrapper view instead of `tabBar` — still a **single** on-screen bar (no extra “strip” above tabs).
final class AnchoredDropdownExampleTabBarHostView: UIView, FKAnchoredDropdownTabBarHost {
  let tabBar: FKTabBar = {
    let bar = FKTabBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  /// Wrapper around the tab row and hairline; use as `sourceView` when demonstrating a non-tab-bar anchor.
  let chromeBar: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private let divider = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  var view: UIView { self }

  private func commonInit() {
    backgroundColor = .clear
    chromeBar.backgroundColor = .systemBackground

    divider.translatesAutoresizingMaskIntoConstraints = false
    divider.backgroundColor = UIColor.separator.withAlphaComponent(0.65)

    addSubview(chromeBar)
    chromeBar.addSubview(tabBar)
    chromeBar.addSubview(divider)

    NSLayoutConstraint.activate([
      chromeBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      chromeBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      chromeBar.trailingAnchor.constraint(equalTo: trailingAnchor),

      tabBar.topAnchor.constraint(equalTo: chromeBar.topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: chromeBar.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: chromeBar.trailingAnchor),
      tabBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

      divider.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
      divider.leadingAnchor.constraint(equalTo: chromeBar.leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: chromeBar.trailingAnchor),
      divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
      divider.bottomAnchor.constraint(equalTo: chromeBar.bottomAnchor),
    ])
  }
}
