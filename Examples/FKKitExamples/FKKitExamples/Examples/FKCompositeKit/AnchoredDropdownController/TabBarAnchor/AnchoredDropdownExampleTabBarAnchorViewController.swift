import UIKit
import FKCompositeKit

/// Dropdown anchored to **`FKTabBar`** (default). Tabs, switch animations, callbacks — no custom anchor APIs.
///
/// Uses `AnchoredDropdownExampleTabBarHostView` so the tab row stays **top-aligned** with natural height.
/// `FKDefaultTabDropdownTabBarHost` pins `FKTabBar` to the full host height and vertically centers items (wrong here).
final class AnchoredDropdownExampleTabBarAnchorViewController: UIViewController {
  private let logView = AnchoredDropdownExampleLogHelpers.makeCallbackLogTextView()
  private let host = AnchoredDropdownExampleTabBarHostView()
  private lazy var dropdown: FKAnchoredDropdownController<AnchoredDropdownExampleTabID> = {
    AnchoredDropdownExampleDropdownFactory.makeController(tabBarHost: host) { [weak self] line in
      self?.appendLog(line)
    }
  }()

  private let animationControl = UISegmentedControl(items: ["Replace", "Dismiss→Present"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tab bar anchor"
    view.backgroundColor = .systemBackground
    setupNavigation()
    setupChild()
    setupLogView()
    appendLog("Anchor = embedded FKTabBar (default). Tap tabs; toggle replace vs dismiss→present above.")
  }

  private func setupNavigation() {
    animationControl.selectedSegmentIndex = 0
    animationControl.addTarget(self, action: #selector(didChangeAnimationStyle), for: .valueChanged)
    navigationItem.titleView = animationControl

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(didTapOpenFilters)),
      UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(didTapClose)),
    ]
  }

  private func setupChild() {
    dropdown.embed(in: self)
  }

  private func setupLogView() {
    AnchoredDropdownExampleLogHelpers.installLogView(logView, in: view, below: dropdown.view)
  }

  private func appendLog(_ text: String) {
    AnchoredDropdownExampleLogHelpers.appendLogLine(text, to: logView)
  }

  @objc private func didTapOpenFilters() {
    dropdown.open(tab: .filters, animated: true)
  }

  @objc private func didTapClose() {
    dropdown.close(animated: true)
  }

  @objc private func didChangeAnimationStyle() {
    switch animationControl.selectedSegmentIndex {
    case 0:
      dropdown.configuration.switchAnimationStyle = .replaceInPlace(animation: .crossfade(duration: 0.18))
      appendLog("switchAnimationStyle = replaceInPlace(crossfade)")
    default:
      dropdown.configuration.switchAnimationStyle = .dismissThenPresent(dismissAnimated: false, presentAnimated: true)
      appendLog("switchAnimationStyle = dismissThenPresent")
    }
  }
}
