import UIKit
import FKUIKit

/// A shared UIKit page scaffold for `FKPresentationController` examples.
///
/// This keeps example pages consistent and easy to copy: a readable header, a control stack,
/// and a single primary action to present content.
class FKPresentationExamplePageViewController: UIViewController {
  let scrollView = UIScrollView()
  let stack = UIStackView()

  private let headerView = FKExampleHeaderView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    setupDismissKeyboardOnTap()
  }

  func setHeader(title: String, subtitle: String, notes: String? = nil) {
    headerView.titleLabel.text = title
    headerView.subtitleLabel.text = subtitle
    headerView.notesLabel.text = notes
    headerView.notesLabel.isHidden = (notes?.isEmpty ?? true)
  }

  func addSectionTitle(_ title: String) {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.numberOfLines = 0
    stack.addArrangedSubview(label)
  }

  func addSpacer(_ height: CGFloat = 8) {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    stack.addArrangedSubview(v)
  }

  func addView(_ view: UIView) {
    stack.addArrangedSubview(view)
  }

  func addPrimaryButton(title: String, action: @escaping () -> Void) {
    let button = UIButton(type: .system)
    button.configuration = .filled()
    button.configuration?.cornerStyle = .large
    button.setTitle(title, for: .normal)
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    stack.addArrangedSubview(button)
  }

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stack.translatesAutoresizingMaskIntoConstraints = false

    stack.axis = .vertical
    stack.spacing = 12

    view.addSubview(scrollView)
    scrollView.addSubview(stack)

    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
    ])

    stack.addArrangedSubview(headerView)
  }

  private func setupDismissKeyboardOnTap() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc private func endEditing() {
    view.endEditing(true)
  }
}

