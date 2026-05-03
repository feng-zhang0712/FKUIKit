import UIKit
import FKUIKit

/// Accessibility (VoiceOver) checklist for `FKTabBar`.
///
/// How to verify:
/// - Settings → Accessibility → VoiceOver (turn it on)
/// - Swipe through each tab:
///   - Selected tab should announce "Selected"
///   - Disabled tab should announce "Dimmed" / not enabled
///   - Badge value should be included in the accessibility value
///
/// FKTabBar boundaries:
/// - FKTabBar is UI-only. It does not manage navigation, pages, or controller state.
final class FKTabBarAccessibilityExampleViewController: UIViewController {
  private var items: [FKTabBarItem] = []
  private lazy var tabView = FKTabBar(items: items, selectedIndex: 0)

  private let statusLabel = UILabel()
  private let disableSwitch = UISwitch()
  private let badgeSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Accessibility"
    view.backgroundColor = .systemBackground

    items = FKTabBarExampleSupport.makeItems(5)
    items[0].badge = .dot
    items[1].badge = .count(12)
    items[2].badge = .count(120)
    items[3].badge = .text("NEW")
    items[4].badge = .none
    tabView.reload(items: items)

    let stack = FKTabBarExampleSupport.makeRootStack(in: view, topInset: 16)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("VoiceOver checklist"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Turn on VoiceOver and swipe across tabs. Selected/disabled/badge should be announced correctly."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("This demo only changes a UIView's state. FKTabBar does not provide any TabBarController."))

    // Disable one tab.
    let disableRow = UIStackView()
    disableRow.axis = .horizontal
    disableRow.alignment = .center
    disableRow.spacing = 10
    let disableLabel = UILabel()
    disableLabel.font = .preferredFont(forTextStyle: .body)
    disableLabel.text = "Disable Tab #3"
    disableRow.addArrangedSubview(disableLabel)
    disableRow.addArrangedSubview(UIView())
    disableSwitch.isOn = false
    disableSwitch.addAction(UIAction { [weak self] _ in
      self?.applyToggles()
    }, for: .valueChanged)
    disableRow.addArrangedSubview(disableSwitch)
    stack.addArrangedSubview(disableRow)

    // Toggle badges (local updates).
    let badgeRow = UIStackView()
    badgeRow.axis = .horizontal
    badgeRow.alignment = .center
    badgeRow.spacing = 10
    let badgeLabel = UILabel()
    badgeLabel.font = .preferredFont(forTextStyle: .body)
    badgeLabel.text = "Show badges"
    badgeRow.addArrangedSubview(badgeLabel)
    badgeRow.addArrangedSubview(UIView())
    badgeSwitch.isOn = true
    badgeSwitch.addAction(UIAction { [weak self] _ in
      self?.applyToggles()
    }, for: .valueChanged)
    badgeRow.addArrangedSubview(badgeSwitch)
    stack.addArrangedSubview(badgeRow)

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select #1") { [weak self] in
      self?.tabView.setSelectedIndex(0, animated: true, reason: .programmatic)
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select #4") { [weak self] in
      self?.tabView.setSelectedIndex(3, animated: true, reason: .programmatic)
    })
    stack.addArrangedSubview(actions)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Ready."
    stack.addArrangedSubview(statusLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 56),
    ])

    tabView.onSelectionChanged = { [weak self] item, idx, _ in
      self?.statusLabel.text = "Selected: \(idx) (\(item.titleText ?? item.id))"
    }
  }

  private func applyToggles() {
    if items.indices.contains(2) {
      items[2].isEnabled = !disableSwitch.isOn
      items[2].title = .init(normal: .init(text: items[2].isEnabled ? "Inbox" : "Inbox (Disabled)"))
      items[2].accessibilityLabel = items[2].titleText
    }

    if badgeSwitch.isOn {
      tabView.setBadge(.dot, at: 0, animated: true)
      tabView.setBadge(.count(12), at: 1, animated: true)
      tabView.setBadge(.count(120), at: 2, animated: true)
      tabView.setBadge(.text("NEW"), at: 3, animated: true)
      tabView.setBadge(.none, at: 4, animated: true)
    } else {
      for i in items.indices {
        tabView.setBadge(.none, at: i, animated: true)
      }
    }

    tabView.reload(items: items, updatePolicy: .preserveSelection)
    statusLabel.text = "Updated: disabled=\(disableSwitch.isOn), badges=\(badgeSwitch.isOn)"
  }
}

