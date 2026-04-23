import UIKit

/// Shared UI helpers used by every UIKit demo page.
enum FKToastDemoUI {
  static func makeScrollContent(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 14
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    viewController.view.addSubview(scroll)

    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
      stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
    ])
    return stack
  }

  static func section(title: String, description: String, body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.text = title

    let descriptionLabel = UILabel()
    descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
    descriptionLabel.adjustsFontForContentSizeCategory = true
    descriptionLabel.textColor = .secondaryLabel
    descriptionLabel.numberOfLines = 0
    descriptionLabel.text = description

    wrap.addArrangedSubview(titleLabel)
    wrap.addArrangedSubview(descriptionLabel)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func row(_ views: [UIView]) -> UIStackView {
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    return row
  }

  static func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 10
    button.heightAnchor.constraint(equalToConstant: 42).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }
}

/// Base controller that provides a consistent scrollable surface.
class FKToastDemoBaseViewController: UIViewController {
  var contentStack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    contentStack = FKToastDemoUI.makeScrollContent(in: self)
  }
}
