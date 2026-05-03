import UIKit
import FKUIKit

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
