import UIKit
import FKUIKit

enum FKCornerShadowExampleSupport {
  private static var didConfigureDefaults = false

  static func configureDefaultsIfNeeded() {
    guard !didConfigureDefaults else { return }
    didConfigureDefaults = true
    FKCornerShadowManager.shared.configureDefaultStyle { style in
      style.corners = .allCorners
      style.cornerRadius = 14
      style.fillColor = .secondarySystemBackground
      style.border = .solid(color: .separator, width: 0.6)
      style.shadow = FKCornerShadowElevation(
        color: .black,
        opacity: 0.12,
        offset: CGSize(width: 0, height: 4),
        blur: 10,
        spread: 0,
        edges: .all
      )
    }
  }

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)
    return (scrollView, stack)
  }

  static func pinRootScrollStack(scrollView: UIScrollView, stack: UIStackView, in view: UIView) {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  static func makeSection(title: String, subtitle: String) -> UIStackView {
    let section = UIStackView()
    section.axis = .vertical
    section.spacing = 8

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.text = title

    let subtitleLabel = UILabel()
    subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle

    section.addArrangedSubview(titleLabel)
    section.addArrangedSubview(subtitleLabel)
    return section
  }

  static func makeDemoCard(height: CGFloat = 88) -> UIView {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    v.backgroundColor = .systemBackground
    return v
  }

  static func makeActionButton(title: String, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system)
    b.translatesAutoresizingMaskIntoConstraints = false
    b.setTitle(title, for: .normal)
    b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    b.backgroundColor = .tertiarySystemFill
    b.layer.cornerRadius = 8
    b.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return b
  }
}
