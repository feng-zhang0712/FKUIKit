import UIKit
import FKUIKit

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
