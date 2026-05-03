import UIKit
import FKUIKit

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
