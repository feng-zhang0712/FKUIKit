import UIKit
import FKUIKit

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
