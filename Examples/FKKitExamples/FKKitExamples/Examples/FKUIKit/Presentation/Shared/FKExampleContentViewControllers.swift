import UIKit

final class FKExampleLabelContentViewController: UIViewController {
  private let text: String

  init(text: String) {
    self.text = text
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.text = text
    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .preferredFont(forTextStyle: .title3)
    label.translatesAutoresizingMaskIntoConstraints = false

    let body = UILabel()
    body.text = "This is example content. Replace this controller with your own feature screen."
    body.numberOfLines = 0
    body.textAlignment = .center
    body.font = .preferredFont(forTextStyle: .body)
    body.textColor = .secondaryLabel
    body.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [label, body])
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}

final class FKExampleTableContentViewController: UITableViewController {
  private let rowCount: Int

  init(rowCount: Int = 40) {
    self.rowCount = rowCount
    super.init(style: .plain)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rowCount }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var configuration = cell.defaultContentConfiguration()
    configuration.text = "Row \(indexPath.row + 1)"
    configuration.secondaryText = "Scroll to the top/bottom, then drag the sheet to see gesture handoff."
    configuration.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = configuration
    return cell
  }
}

final class FKExampleFormContentViewController: UIViewController, UITextViewDelegate {
  private let usesScrollView: Bool
  private let stack = UIStackView()
  private let scrollView = UIScrollView()

  init(usesScrollView: Bool) {
    self.usesScrollView = usesScrollView
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = "Keyboard avoidance content"
    title.font = .preferredFont(forTextStyle: .title2)

    let subtitle = UILabel()
    subtitle.text = "This page intentionally contains inputs near the bottom to demonstrate keyboard avoidance."
    subtitle.font = .preferredFont(forTextStyle: .body)
    subtitle.textColor = .secondaryLabel
    subtitle.numberOfLines = 0

    let name = UITextField()
    name.placeholder = "Name"
    name.borderStyle = .roundedRect

    let email = UITextField()
    email.placeholder = "Email"
    email.borderStyle = .roundedRect
    email.keyboardType = .emailAddress

    let note = UITextView()
    note.delegate = self
    note.layer.borderWidth = 1 / UIScreen.main.scale
    note.layer.borderColor = UIColor.separator.cgColor
    note.layer.cornerRadius = 10
    note.font = .preferredFont(forTextStyle: .body)
    note.text = "Notes…"
    note.textColor = .secondaryLabel
    note.heightAnchor.constraint(equalToConstant: 140).isActive = true

    let spacer = UIView()
    spacer.translatesAutoresizingMaskIntoConstraints = false
    spacer.heightAnchor.constraint(equalToConstant: 420).isActive = true

    [title, subtitle, name, email, spacer, note].forEach { stack.addArrangedSubview($0) }

    if usesScrollView {
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(scrollView)
      scrollView.addSubview(stack)
      NSLayoutConstraint.activate([
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        scrollView.topAnchor.constraint(equalTo: view.topAnchor),
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

        stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
        stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
        stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
        stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
        stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
      ])
    } else {
      view.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
        stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
      ])
    }
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.textColor == .secondaryLabel {
      textView.text = nil
      textView.textColor = .label
    }
  }
}

