import UIKit
import FKUIKit

/// Demonstrates performance-sensitive usage patterns.
///
/// Key points:
/// - Prefer local updates (e.g. `setBadge(at:)`) over `reloadData()` when only a subset changes.
/// - Scrollable mode with many items should remain responsive (selection, indicator, and auto-scroll).
/// - This page intentionally stresses frequent updates on the main thread to reveal layout thrash.
final class FKTabBarPerformanceExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(isScrollable: true, widthMode: .intrinsic))
  private var items: [FKTabBarItem] = []
  private lazy var tabView = FKTabBar(items: items, selectedIndex: 0, configuration: configuration)

  private let countControl = UISegmentedControl(items: ["50", "100", "200"])
  private let modeControl = UISegmentedControl(items: ["Scrollable", "FixedEqual"])
  private let statusLabel = UILabel()
  private var timer: Timer?
  private var tick: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Performance"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Many items + frequent local updates"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("This page generates many items and updates badges frequently via setBadge(at:) to avoid full reload. FKTabBar does not own any controller/pager."))

    countControl.selectedSegmentIndex = 0
    countControl.addAction(UIAction { [weak self] _ in self?.applyItemCount() }, for: .valueChanged)
    stack.addArrangedSubview(countControl)

    modeControl.selectedSegmentIndex = 0
    modeControl.addAction(UIAction { [weak self] _ in self?.applyLayoutMode() }, for: .valueChanged)
    stack.addArrangedSubview(modeControl)

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Start updates") { [weak self] in self?.start() })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Stop updates") { [weak self] in self?.stop() })
    stack.addArrangedSubview(actions)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Idle"
    stack.addArrangedSubview(statusLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 56),
    ])

    applyItemCount()
    applyLayoutMode()
  }

  deinit {
    stop()
  }

  private func applyItemCount() {
    let count = [50, 100, 200][countControl.selectedSegmentIndex]
    items = (0..<count).map { idx in
      FKTabBarItem(
        id: "p-\(idx)",
        title: .init(normal: .init(text: "Item \(idx + 1)")),
        image: .init(normal: .init(source: .systemSymbol(name: "circle"))),
        accessibilityLabel: "Item \(idx + 1)"
      )
    }
    tabView.reload(items: items, updatePolicy: .resetSelection)
    tick = 0
    statusLabel.text = "Generated \(count) items. Updates stopped."
  }

  private func applyLayoutMode() {
    if modeControl.selectedSegmentIndex == 0 {
      configuration.layout.isScrollable = true
      configuration.layout.widthMode = .intrinsic
      configuration.layout.itemSpacing = 10
      configuration.layout.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
      configuration.layout.selectionScrollPosition = .center
    } else {
      configuration.layout.isScrollable = false
      configuration.layout.widthMode = .fillEqually
      configuration.layout.itemSpacing = 0
      configuration.layout.contentInsets = .zero
    }
    tabView.configuration = configuration
  }

  private func start() {
    stop()
    timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
      self?.tickOnce()
    }
    statusLabel.text = "Running updates… (local setBadge)"
  }

  private func stop() {
    timer?.invalidate()
    timer = nil
  }

  private func tickOnce() {
    guard !items.isEmpty else { return }
    tick += 1
    // Update a handful of random indices to simulate incoming notifications.
    for idx in (0..<6).map({ _ in Int.random(in: 0..<items.count) }) {
      let badge: FKTabBarBadgeContent
      switch Int.random(in: 0..<4) {
      case 0: badge = .none
      case 1: badge = .dot
      case 2: badge = .count(Int.random(in: 0...120))
      default: badge = .text("!")
      }
      tabView.setBadge(badge, at: idx, animated: false)
    }
    statusLabel.text = "Tick \(tick): updated ~6 badges via setBadge(at:)"
  }
}

