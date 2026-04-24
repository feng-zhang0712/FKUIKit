import UIKit
import FKUIKit

/// Demonstrates badge mapping between `FKTabBarItem.badge` and the underlying `FKBadge` rendering.
///
/// Key points:
/// - Badges are per-item and are best updated via local APIs (avoid full reload when only badges change).
/// - Number overflow (e.g. 99+) is handled by `FKBadge` configuration (if provided) and TabBar's mapping.
/// - VoiceOver should read selected state and badge value via `accessibilityValue`.
final class FKTabBarBadgeUpdatesExampleViewController: UIViewController {
  private var items = FKTabBarExampleSupport.makeItems(6)
  private lazy var tabView = FKTabBar(items: items, selectedIndex: 0)
  private lazy var verticalTabView: FKTabBar = {
    var config = FKTabBarDefaults.defaultConfiguration
    config.layout.itemLayoutDirection = .vertical
    config.layout.isScrollable = false
    config.layout.widthMode = .fillEqually
    config.layout.itemSpacing = 0
    return FKTabBar(items: items, selectedIndex: 0, configuration: config)
  }()
  private let statusLabel = UILabel()
  private let anchorControl = UISegmentedControl(items: ["TopTrailing", "TopLeading", "Center"])
  private let offsetX = UISlider()
  private let offsetY = UISlider()
  private let offsetValueLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Badge updates"
    view.backgroundColor = .systemBackground

    // Initial badge setup.
    items[0].badge.state.normal = .dot
    items[1].badge.state.normal = .count(3)
    items[2].badge.state.normal = .count(128) // should present as 99+ depending on badge configuration
    items[3].badge.state.normal = .text("NEW")
    items[4].badge.state.normal = .none
    items[5].badge.state.normal = .dot
    tabView.reload(items: items)
    verticalTabView.reload(items: items)

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Dot / number / text / none + local updates"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tap 'Randomize' to update a few badges via setBadge(at:). FKTabBar is UI-only and does not manage controllers."))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("VoiceOver: selected tabs should read Selected + badge value (if any)."))
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Badge placement controls (applies to both horizontal + vertical)"))

    anchorControl.selectedSegmentIndex = 0
    anchorControl.addAction(UIAction { [weak self] _ in
      self?.applyBadgePlacement()
    }, for: .valueChanged)
    stack.addArrangedSubview(anchorControl)

    offsetX.minimumValue = -20
    offsetX.maximumValue = 20
    offsetX.value = 6
    offsetX.addAction(UIAction { [weak self] _ in self?.applyBadgePlacement() }, for: .valueChanged)
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("badge.offset.x"))
    stack.addArrangedSubview(offsetX)

    offsetY.minimumValue = -20
    offsetY.maximumValue = 20
    offsetY.value = -4
    offsetY.addAction(UIAction { [weak self] _ in self?.applyBadgePlacement() }, for: .valueChanged)
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("badge.offset.y"))
    stack.addArrangedSubview(offsetY)

    offsetValueLabel.font = .preferredFont(forTextStyle: .footnote)
    offsetValueLabel.textColor = .secondaryLabel
    offsetValueLabel.numberOfLines = 0
    stack.addArrangedSubview(offsetValueLabel)

    statusLabel.font = .preferredFont(forTextStyle: .body)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Updates: 0"
    stack.addArrangedSubview(statusLabel)

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Randomize") { [weak self] in
      self?.randomizeBadges()
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Clear all") { [weak self] in
      self?.clearBadges()
    })
    stack.addArrangedSubview(actions)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    verticalTabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    view.addSubview(verticalTabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 56),

      verticalTabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      verticalTabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      verticalTabView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 12),
      verticalTabView.heightAnchor.constraint(equalToConstant: 76),
    ])

    // Keep both tab bars in sync so placement tuning is easy to see.
    tabView.onSelectionChanged = { [weak self] _, index, reason in
      guard let self else { return }
      self.verticalTabView.setSelectedIndex(index, animated: reason == .userTap, notify: false, reason: .programmatic)
    }
    verticalTabView.onSelectionChanged = { [weak self] _, index, reason in
      guard let self else { return }
      self.tabView.setSelectedIndex(index, animated: reason == .userTap, notify: false, reason: .programmatic)
    }
    applyBadgePlacement()
  }

  private var updateCount: Int = 0

  private func randomizeBadges() {
    let indices = Array(0..<items.count).shuffled().prefix(3)
    for idx in indices {
      let roll = Int.random(in: 0..<5)
      let badge: FKTabBarBadgeContent
      switch roll {
      case 0: badge = .none
      case 1: badge = .dot
      case 2: badge = .count(Int.random(in: 0...8))
      case 3: badge = .count(Int.random(in: 90...140)) // stress 99+ overflow
      default: badge = .text(["NEW", "HOT", "VIP"].randomElement() ?? "NEW")
      }
      items[idx].badge.state.normal = badge
      tabView.setBadge(badge, at: idx, animated: true)
    }
    updateCount += 1
    statusLabel.text = "Updates: \(updateCount) (local badge updates, no full reload)"
  }

  private func clearBadges() {
    for idx in items.indices {
      items[idx].badge.state.normal = .none
      tabView.setBadge(.none, at: idx, animated: true)
      verticalTabView.setBadge(.none, at: idx, animated: true)
    }
    updateCount += 1
    statusLabel.text = "Updates: \(updateCount) (cleared)"
  }

  private func applyBadgePlacement() {
    let anchor: FKBadgeAnchor = {
      switch anchorControl.selectedSegmentIndex {
      case 1: return .topLeading
      case 2: return .center
      default: return .topTrailing
      }
    }()
    let offset = UIOffset(horizontal: CGFloat(offsetX.value), vertical: CGFloat(offsetY.value))
    offsetValueLabel.text = "anchor: \(anchor)\noffset: (\(Int(offset.horizontal)), \(Int(offset.vertical)))"

    // Update item models, then reload while preserving selection/indicator state.
    for idx in items.indices {
      items[idx].badge.anchor = anchor
      items[idx].badge.offset = offset
    }
    tabView.reload(items: items, updatePolicy: .preserveSelection)
    verticalTabView.reload(items: items, updatePolicy: .preserveSelection)
  }
}

