import UIKit
import FKCompositeKit

/// Custom **`UIView`** anchor only (no visible `FKTabBar`). Tap the bar to call `toggle(tab:)`; Open/Close use the same controller APIs.
final class AnchoredDropdownExampleCustomAnchorViewController: UIViewController {
  private let logView = UITextView()
  private let host = AnchoredDropdownExampleCustomAnchorHostView()
  private lazy var dropdown: FKAnchoredDropdownController<AnchoredDropdownExampleTabID> = {
    AnchoredDropdownExampleDropdownFactory.makeController(tabBarHost: host) { [weak self] line in
      self?.appendLog(line)
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom anchor"
    view.backgroundColor = .systemBackground
    setupAnchorInteraction()
    setupNavigation()
    setupChild()
    setupLogView()
    applyCustomAnchor()
    appendLog("Anchor source = anchorControl (UIButton). FKTabBar is off-screen; tap the bar or use Open/Close.")
  }

  private func setupAnchorInteraction() {
    host.anchorControl.addTarget(self, action: #selector(didTapAnchorControl), for: .touchUpInside)
  }

  private func setupNavigation() {
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

  private func applyCustomAnchor() {
    dropdown.setCustomAnchor(source: host.anchorControl, overlayHost: host)
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

  @objc private func didTapAnchorControl() {
    dropdown.toggle(tab: .filters, animated: true)
  }

  @objc private func didTapOpenFilters() {
    dropdown.open(tab: .filters, animated: true)
  }

  @objc private func didTapClose() {
    dropdown.close(animated: true)
  }
}
