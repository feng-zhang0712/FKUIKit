import UIKit
import FKUIKit

final class FKTabBarScrollableManyTabsExampleViewController: UIViewController {
  private var configuration = FKTabBarConfiguration(
    layout: FKTabBarLayoutConfiguration(
      isScrollable: true,
      itemSpacing: 10,
      contentInsets: .init(top: 0, leading: 16, bottom: 0, trailing: 16),
      contentAlignment: .leading,
      titleOverflowMode: .automaticWidth,
      minimumItemHeight: 46
    )
  )
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(11), selectedIndex: 0, configuration: configuration)
  private let infoLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "10+ tabs"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Scrollable tabs with automatic centering"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Selecting a tab should keep it visible and near center."))
    infoLabel.font = .preferredFont(forTextStyle: .body)
    infoLabel.numberOfLines = 0
    infoLabel.text = "Selected index: 0"
    stack.addArrangedSubview(infoLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])

    tabView.onSelectionChanged = { [weak self] item, index, _ in
      self?.infoLabel.text = "Selected index: \(index), title: \(item.titleText ?? item.id)"
    }
  }
}

final class FKTabBarLongTitleStrategyExampleViewController: UIViewController {
  private var modeIndex = 0
  private var configuration = FKTabBarConfiguration(layout: .init())
  private lazy var tabView = FKTabBar(items: FKTabBarExampleSupport.makeLongTitleItems(), selectedIndex: 1, configuration: configuration)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long title"
    view.backgroundColor = .systemBackground

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Long title overflow strategy"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Switch mode to compare text rendering trade-offs."))

    let segmented = UISegmentedControl(items: ["Truncate", "Shrink", "Auto", "Fixed"])
    segmented.selectedSegmentIndex = 0
    segmented.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.modeIndex = control.selectedSegmentIndex
      self.applyMode()
    }, for: .valueChanged)
    stack.addArrangedSubview(segmented)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  private func applyMode() {
    switch modeIndex {
    case 0:
      configuration.layout.titleOverflowMode = .truncate
    case 1:
      configuration.layout.titleOverflowMode = .shrink(minimumScaleFactor: 0.75)
    case 2:
      configuration.layout.titleOverflowMode = .automaticWidth
    default:
      configuration.layout.titleOverflowMode = .fixedWidth(120)
    }
    tabView.configuration = configuration
  }
}

