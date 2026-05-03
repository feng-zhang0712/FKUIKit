import UIKit

final class AnchoredDropdownExampleSortPanelViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    preferredContentSize = CGSize(width: 0, height: 320)

    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = "Sort"
    title.font = .preferredFont(forTextStyle: .headline)

    let hint = UILabel()
    hint.text = "Tap any option to see immediate height stability."
    hint.textColor = .secondaryLabel
    hint.font = .preferredFont(forTextStyle: .subheadline)
    hint.numberOfLines = 0

    let options = ["Recommended", "Distance", "Price ↑", "Price ↓", "Rating"]
    let buttons = options.map { text -> UIButton in
      var config = UIButton.Configuration.filled()
      config.title = text
      config.baseBackgroundColor = .secondarySystemBackground
      config.baseForegroundColor = .label
      let b = UIButton(configuration: config)
      b.contentHorizontalAlignment = .leading
      b.addTarget(self, action: #selector(didTapOption), for: .touchUpInside)
      return b
    }

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(hint)
    buttons.forEach { stack.addArrangedSubview($0) }

    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  @objc private func didTapOption() {
    // no-op: used to demonstrate tap handling inside content
  }
}
