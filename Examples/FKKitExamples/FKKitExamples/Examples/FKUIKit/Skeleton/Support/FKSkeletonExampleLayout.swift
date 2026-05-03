import UIKit

/// Shared vertical form layout for Skeleton examples (scroll + inset stack).
enum FKSkeletonExampleLayout {

  @discardableResult
  static func installScrollableForm(in view: UIView, safeArea: UILayoutGuide) -> UIStackView {
    let scroll = UIScrollView()
    scroll.alwaysBounceVertical = true
    scroll.keyboardDismissMode = .interactive
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: safeArea.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
    ])
    return stack
  }

  static func sectionHeader(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func caption(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func primaryButton(title: String, primaryAction: UIAction) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.addAction(primaryAction, for: .touchUpInside)
    return button
  }

  static func borderedHostView() -> UIView {
    let view = UIView()
    view.layer.cornerCurve = .continuous
    view.layer.cornerRadius = 12
    view.layer.borderWidth = 1 / UIScreen.main.scale
    view.layer.borderColor = UIColor.separator.cgColor
    view.clipsToBounds = true
    return view
  }
}
