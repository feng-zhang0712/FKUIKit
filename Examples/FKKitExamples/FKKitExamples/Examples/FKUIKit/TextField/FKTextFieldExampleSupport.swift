import UIKit
import FKUIKit

class FKTextFieldExamplePageViewController: UIViewController {
  let scrollView = UIScrollView()
  let stack = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    setupDismissKeyboardOnTap()
  }

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = 14
    view.addSubview(scrollView)
    scrollView.addSubview(stack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
    ])
  }

  func addSection(title: String, note: String) {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    let noteLabel = UILabel()
    noteLabel.text = note
    noteLabel.textColor = .secondaryLabel
    noteLabel.font = .preferredFont(forTextStyle: .footnote)
    noteLabel.numberOfLines = 0
    stack.addArrangedSubview(noteLabel)
  }

  func addField(title: String, field: FKTextField, ruleHint: String? = nil) {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    row.addArrangedSubview(field)
    if let ruleHint, !ruleHint.isEmpty {
      let hintLabel = UILabel()
      hintLabel.text = ruleHint
      hintLabel.textColor = .tertiaryLabel
      hintLabel.font = .preferredFont(forTextStyle: .caption2)
      hintLabel.numberOfLines = 0
      row.addArrangedSubview(hintLabel)
    }
    stack.addArrangedSubview(row)
  }

  func addCustomView(title: String, view customView: UIView) {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    row.addArrangedSubview(customView)
    stack.addArrangedSubview(row)
  }

  private func setupDismissKeyboardOnTap() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(endEdit))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc private func endEdit() {
    view.endEditing(true)
  }
}
