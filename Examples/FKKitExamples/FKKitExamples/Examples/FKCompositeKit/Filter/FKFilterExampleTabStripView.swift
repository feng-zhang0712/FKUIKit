import UIKit
import FKCompositeKit
import FKUIKit

/// Chrome for Filter examples: **top-aligned** tab row (no bottom hairline — divider removed per design).
///
/// Use as ``FKAnchoredDropdownTabBarHost`` so items align to the top when titles wrap to two lines.
final class FKFilterExampleTabStripView: UIView, FKAnchoredDropdownTabBarHost {
  let tabBar: FKTabBar = {
    let bar = FKTabBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    return bar
  }()

  private let chromeBar: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .systemBackground
    return v
  }()

  var view: UIView { self }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  private func commonInit() {
    backgroundColor = .clear

    addSubview(chromeBar)
    chromeBar.addSubview(tabBar)

    NSLayoutConstraint.activate([
      chromeBar.topAnchor.constraint(equalTo: topAnchor),
      chromeBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      chromeBar.trailingAnchor.constraint(equalTo: trailingAnchor),
      chromeBar.bottomAnchor.constraint(equalTo: bottomAnchor),

      tabBar.topAnchor.constraint(equalTo: chromeBar.topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: chromeBar.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: chromeBar.trailingAnchor),
      tabBar.bottomAnchor.constraint(equalTo: chromeBar.bottomAnchor),
      tabBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
    ])
  }
}
