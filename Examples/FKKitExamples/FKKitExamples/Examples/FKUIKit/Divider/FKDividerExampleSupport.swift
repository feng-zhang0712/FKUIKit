import UIKit
import FKUIKit

// MARK: - Shared chrome

enum FKDividerExampleSupport {

  static func makeScrollStack(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
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

  static func card(title: String, description: String, content: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 10
    wrap.backgroundColor = .secondarySystemGroupedBackground
    wrap.layer.cornerRadius = 12
    wrap.isLayoutMarginsRelativeArrangement = true
    wrap.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

    let t = UILabel()
    t.text = title
    t.font = .preferredFont(forTextStyle: .headline)
    let d = UILabel()
    d.text = description
    d.textColor = .secondaryLabel
    d.numberOfLines = 0
    d.font = .preferredFont(forTextStyle: .footnote)

    wrap.addArrangedSubview(t)
    wrap.addArrangedSubview(d)
    wrap.addArrangedSubview(content)
    return wrap
  }

  static func sampleBox(height: CGFloat = 56) -> UIView {
    let v = UIView()
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 10
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    return v
  }
}

class FKDividerExampleBaseViewController: UIViewController {
  var stack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    stack = FKDividerExampleSupport.makeScrollStack(in: self)
  }
}
