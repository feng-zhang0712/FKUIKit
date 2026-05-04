import UIKit
import FKCompositeKit
import FKUIKit

/// Host for the **custom-anchor** demo only: a visible **custom control** acts as the anchor geometry source;
/// `FKTabBar` stays in the hierarchy (required by `FKAnchoredDropdownController`) but is laid out **off-screen**
/// so it does not appear in the UI — interaction uses `open` / `close` / `toggle` from code instead of tab taps.
final class AnchoredDropdownExampleCustomAnchorHostView: UIView, FKAnchoredDropdownTabBarHost {
  /// User-visible bar; also the ``FKAnchoredDropdownController/setAnchor(source:overlayHost:)`` source view.
  let anchorControl: UIButton = {
    var configuration = UIButton.Configuration.filled()
    configuration.title = "Custom anchor — tap to toggle Filters"
    configuration.titleAlignment = .center
    configuration.baseForegroundColor = .label
    configuration.baseBackgroundColor = .systemBackground
    configuration.cornerStyle = .fixed
    configuration.background.cornerRadius = 0
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = UIFont.preferredFont(forTextStyle: .footnote)
      return outgoing
    }
    let button = UIButton(configuration: configuration)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.accessibilityHint = "Toggles the Filters dropdown anchored below this bar."
    return button
  }()

  private let divider: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.separator.withAlphaComponent(0.65)
    return view
  }()

  let tabBar: FKTabBar = {
    let bar = FKTabBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.isHidden = true
    return bar
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
    addSubview(anchorControl)
    addSubview(divider)
    addSubview(tabBar)

    NSLayoutConstraint.activate([
      // Same horizontal placement and minimum height as `AnchoredDropdownExampleTabBarHostView`’s `FKTabBar` row.
      anchorControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      anchorControl.leadingAnchor.constraint(equalTo: leadingAnchor),
      anchorControl.trailingAnchor.constraint(equalTo: trailingAnchor),
      anchorControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

      divider.topAnchor.constraint(equalTo: anchorControl.bottomAnchor),
      divider.leadingAnchor.constraint(equalTo: leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: trailingAnchor),
      divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

      // Keep FKTabBar laid out for internal reload/state, but outside the visible viewport.
      tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 44),
      tabBar.topAnchor.constraint(equalTo: bottomAnchor, constant: 4000),
    ])
  }
}
