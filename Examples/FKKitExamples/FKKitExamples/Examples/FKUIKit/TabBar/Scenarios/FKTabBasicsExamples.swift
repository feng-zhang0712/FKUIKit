import UIKit
import FKUIKit

final class FKTabBarBasicsTextExampleViewController: UIViewController {
  private let tabView: FKTabBar
  private let statusLabel = UILabel()

  init() {
    var items = FKTabBarExampleSupport.makeItems(4)
    items = items.enumerated().map { idx, item in
      var new = item
      new.image = nil
      return new
    }
    tabView = FKTabBar(items: items, selectedIndex: 1)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = "Text tabs"

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Default selection and programmatic switching"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab Item rendered by FKButton. Tap buttons to call setSelectedIndex(_:reason:)."))

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select #1") { [weak self] in self?.tabView.setSelectedIndex(0, reason: .programmatic) })
    actions.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select #3") { [weak self] in self?.tabView.setSelectedIndex(2, reason: .programmatic) })
    stack.addArrangedSubview(actions)

    statusLabel.font = .preferredFont(forTextStyle: .body)
    statusLabel.numberOfLines = 0
    statusLabel.text = "Selected index: 1"
    stack.addArrangedSubview(statusLabel)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 48),
    ])

    tabView.onSelectionChanged = { [weak self] item, index, reason in
      self?.statusLabel.text = "Selected index: \(index), reason: \(reason)"
    }
  }
}

final class FKTabBarBasicsIconTextExampleViewController: UIViewController {
  private let tabView = FKTabBar(items: FKTabBarExampleSupport.makeItems(5), selectedIndex: 0)
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    title = "Icon + text"

    let stack = FKTabBarExampleSupport.makeRootStack(in: view)
    stack.addArrangedSubview(FKTabBarExampleSupport.titleLabel("Icon and text tabs"))
    stack.addArrangedSubview(FKTabBarExampleSupport.captionLabel("Tab Item rendered by FKButton. Verifies icon tint/text style transition for selected and unselected states."))

    label.font = .preferredFont(forTextStyle: .body)
    label.numberOfLines = 0
    label.text = "Selected: Home"
    stack.addArrangedSubview(label)

    tabView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabView)
    NSLayoutConstraint.activate([
      tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabView.heightAnchor.constraint(equalToConstant: 50),
    ])

    tabView.onSelectionChanged = { [weak self] item, index, _ in
      self?.label.text = "Selected: \(item.titleText ?? item.id) (\(index))"
    }
  }
}

