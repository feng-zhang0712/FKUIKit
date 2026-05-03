import UIKit

final class AnchoredDropdownExampleSearchPanelViewController: UIViewController, UITextFieldDelegate {
  private let field = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    preferredContentSize = CGSize(width: 0, height: 180)

    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = "Search"
    title.font = .preferredFont(forTextStyle: .headline)

    field.translatesAutoresizingMaskIntoConstraints = false
    field.borderStyle = .roundedRect
    field.placeholder = "Type to test keyboard avoidance"
    field.returnKeyType = .done
    field.delegate = self

    let hint = UILabel()
    hint.translatesAutoresizingMaskIntoConstraints = false
    hint.text = "Keyboard avoidance comes from FKPresentationController configuration."
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.font = .preferredFont(forTextStyle: .subheadline)

    view.addSubview(title)
    view.addSubview(field)
    view.addSubview(hint)
    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
      title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      field.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
      field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      hint.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 12),
      hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      hint.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
    ])
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
