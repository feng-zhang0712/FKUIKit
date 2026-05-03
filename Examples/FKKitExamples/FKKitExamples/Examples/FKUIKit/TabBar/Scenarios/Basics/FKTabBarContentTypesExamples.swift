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
