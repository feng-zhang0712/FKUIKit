import UIKit
import FKUIKit

final class FKTabBarContentTypesExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeMixedContentItems(), selectedIndex: 0)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content types"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Text / symbol / image / custom view in one unified item model"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab Item rendered by FKButton. Validates text/symbol/image/custom rendering and custom content view provider behavior."))

    tabView.itemViewProvider = { item in
      guard item.customContentIdentifier == "pill" else { return nil }
      // A padded container yields a reasonable hit target and stable intrinsic size.
      let container = UIView()
      container.backgroundColor = .systemPurple
      container.layer.cornerRadius = 10
      container.clipsToBounds = true

      let label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.text = "Custom"
      label.font = .systemFont(ofSize: 12, weight: .semibold)
      label.textAlignment = .center
      label.textColor = .white

      container.addSubview(label)
      NSLayoutConstraint.activate([
        label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
        label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
        label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
        label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
      ])

      container.setContentHuggingPriority(.required, for: .horizontal)
      container.setContentCompressionResistancePriority(.required, for: .horizontal)
      return container
    }

    attachBottom(tabView)
  }

  private func attachBottom(_ tab: UIView) {
    tab.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tab)
    NSLayoutConstraint.activate([
      tab.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tab.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tab.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tab.heightAnchor.constraint(equalToConstant: 56),
    ])
  }
}

final class FKTabBarLayoutRTLExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(itemLayoutDirection: .horizontal))
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(6), selectedIndex: 0, configuration: configuration)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout + RTL"
    view.backgroundColor = .systemBackground
    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Leading/trailing and top/bottom content layout with RTL override"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab Item rendered by FKButton. Switch layout direction and RTL behavior to verify mirrored order and stable spacing."))

    let direction = UISegmentedControl(items: ["Leading+Text", "Top+Bottom"])
    direction.selectedSegmentIndex = 0
    direction.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.itemLayoutDirection = direction.selectedSegmentIndex == 0 ? .horizontal : .vertical
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(direction)

    let rtl = UISegmentedControl(items: ["Auto", "Force LTR", "Force RTL"])
    rtl.selectedSegmentIndex = 0
    rtl.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.rtlBehavior = rtl.selectedSegmentIndex == 1 ? .forceLeftToRight : (rtl.selectedSegmentIndex == 2 ? .forceRightToLeft : .automatic)
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(rtl)

    attachBottom(tabView)
  }

  private func attachBottom(_ tab: UIView) {
    tab.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tab)
    NSLayoutConstraint.activate([
      tab.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tab.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tab.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tab.heightAnchor.constraint(equalToConstant: 64),
    ])
  }
}

final class FKTabBarScrollAndWidthStrategyExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(layout: .init(isScrollable: true, widthMode: .intrinsic))
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeLongTitleItems(), selectedIndex: 0, configuration: configuration)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scroll + Width"
    view.backgroundColor = .systemBackground
    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Auto-scroll target position and width policy comparison"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Compare minimal/center/leading/trailing scroll target and intrinsic/fixed/fill/constrained/custom widths."))

    let scroll = UISegmentedControl(items: ["Minimal", "Center", "Leading", "Trailing"])
    scroll.selectedSegmentIndex = 1
    scroll.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.selectionScrollPosition = [.minimalVisible, .center, .leading, .trailing][scroll.selectedSegmentIndex]
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(scroll)

    let width = UISegmentedControl(items: ["Intrinsic", "Fixed", "Fill", "Range", "Custom"])
    width.selectedSegmentIndex = 0
    width.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.configuration.layout.customWidthProvider = nil
      switch width.selectedSegmentIndex {
      case 1: self.configuration.layout.widthMode = .fixed(120)
      case 2:
        self.configuration.layout.isScrollable = false
        self.configuration.layout.widthMode = .fillEqually
      case 3:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .constrained(min: 80, max: 160)
      case 4:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .intrinsic
        self.configuration.layout.customWidthProvider = { index, _ in index % 2 == 0 ? 90 : 150 }
      default:
        self.configuration.layout.isScrollable = true
        self.configuration.layout.widthMode = .intrinsic
      }
      self.tabView.configuration = self.configuration
    }, for: .valueChanged)
    stack.addArrangedSubview(width)

    attachBottom(tabView)
  }

  private func attachBottom(_ tab: UIView) {
    tab.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tab)
    NSLayoutConstraint.activate([
      tab.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tab.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tab.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tab.heightAnchor.constraint(equalToConstant: 56),
    ])
  }
}

final class FKTabBarBadgeAnchorAndLandscapeExampleViewController: UIViewController {
  private let tabView: FKTabBar

  init() {
    var items = FKTabBarExampleSupport.makeItems(5)
    items[0].badge.state.normal = .dot
    items[0].badge.anchor = .topLeading
    items[0].badge.offset = .init(horizontal: -4, vertical: 0)
    items[1].badge.state.normal = .count(99)
    items[1].badge.anchor = .topTrailing
    items[1].badge.offset = .init(horizontal: 2, vertical: -2)
    items[2].badge.state.normal = .text("NEW")
    items[2].badge.anchor = .center
    items[2].badge.offset = .init(horizontal: 0, vertical: 0)
    items[3].badge.state.normal = .dot
    items[3].badge.anchor = .bottomLeading
    items[3].badge.offset = .init(horizontal: -2, vertical: 2)
    items[4].badge.state.normal = .dot
    items[4].badge.anchor = .bottomTrailing
    items[4].badge.offset = .init(horizontal: 2, vertical: 2)
    tabView = FKTabBar(items: items, selectedIndex: 0)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Badge anchors + landscape"
    view.backgroundColor = .systemBackground
    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Badge anchor positions and rotation stability"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Rotate device to landscape and back to verify indicator, badge, and selected-item scroll state remain correct."))
    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select first") { [weak self] in
      self?.tabView.setSelectedIndex(0, animated: true, reason: .programmatic)
    })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select last") { [weak self] in
      self?.tabView.setSelectedIndex(4, animated: true, reason: .programmatic)
    })
    stack.addArrangedSubview(actions)
    attachBottom(tabView)
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.tabView.realignSelection(animated: false)
    })
  }

  private func attachBottom(_ tab: UIView) {
    tab.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tab)
    NSLayoutConstraint.activate([
      tab.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tab.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tab.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tab.heightAnchor.constraint(equalToConstant: 56),
    ])
  }
}
