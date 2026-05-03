import UIKit
import FKCompositeKit

/// Dropdown anchored to **`FKTabBar`** (default). Tabs, switch animations, callbacks — no custom anchor APIs.
///
/// Uses `AnchoredDropdownExampleTabBarHostView` so the tab row stays **top-aligned** with natural height.
/// `FKDefaultTabDropdownTabBarHost` pins `FKTabBar` to the full host height and vertically centers items (wrong here).
final class AnchoredDropdownExampleTabBarAnchorViewController: UIViewController {
  private let logView = UITextView()
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
    addChild(dropdown)
    dropdown.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(dropdown.view)
    dropdown.didMove(toParent: self)

    NSLayoutConstraint.activate([
      dropdown.view.topAnchor.constraint(equalTo: view.topAnchor),
      dropdown.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dropdown.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dropdown.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupLogView() {
    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.backgroundColor = UIColor.secondarySystemBackground
    logView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logView.layer.cornerRadius = 10
    logView.layer.masksToBounds = true

    view.insertSubview(logView, belowSubview: dropdown.view)
    NSLayoutConstraint.activate([
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: 180),
    ])
    view.bringSubviewToFront(dropdown.view)
  }

  private func appendLog(_ text: String) {
    let line = "[\(AnchoredDropdownExampleLogHelpers.timestamp())] \(text)"
    if logView.text?.isEmpty ?? true {
      logView.text = line
    } else {
      logView.text = (logView.text ?? "") + "\n" + line
    }
    let range = NSRange(location: max(0, logView.text.count - 1), length: 1)
    logView.scrollRangeToVisible(range)
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
