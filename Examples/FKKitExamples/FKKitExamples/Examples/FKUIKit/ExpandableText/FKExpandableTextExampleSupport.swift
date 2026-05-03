import FKUIKit
import UIKit

// MARK: - Demo content

enum FKExpandableTextExampleSupport {
  static let plainParagraph =
    "FKExpandableText truncates long content automatically and lets users toggle between collapsed and expanded states with an action. It works well for article summaries, user bios, review snippets, and message previews. "
    + "The same paragraph repeats so demos always exceed a two- or three-line budget on typical phone widths, making Read more / Collapse visible for testing. "
    + "FKExpandableText truncates long content automatically and lets users toggle between collapsed and expanded states with an action. It works well for article summaries, user bios, review snippets, and message previews."

  static let dynamicShortText = "This is the short text version. Tap the button to switch to a longer one."

  static let dynamicLongText =
    "This is a longer dynamic text sample. It shows that after runtime text updates, the component recalculates truncation, relayouts correctly, and keeps expand/collapse interaction available. This pattern is useful for async API content, refreshed summaries, and live preview after user edits."

  static func attributedRichText() -> NSAttributedString {
    let body =
      "This is a rich text sample with a link: https://www.example.com and an emphasized phrase. Link interaction is handled by UITextView while expand/collapse action remains available. "
      + "Repeated so default three-line collapse reliably shows Read more in the sample app. "
      + "This is a rich text sample with a link: https://www.example.com and an emphasized phrase. Link interaction is handled by UITextView while expand/collapse action remains available."
    let text = NSMutableAttributedString(
      string: body,
      attributes: [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.label,
      ]
    )
    let full = text.string as NSString
    let urlRange = full.range(of: "https://www.example.com")
    if urlRange.location != NSNotFound, let url = URL(string: "https://www.example.com") {
      text.addAttributes([
        .link: url,
        .foregroundColor: UIColor.systemBlue,
        .underlineStyle: NSUnderlineStyle.single.rawValue,
      ], range: urlRange)
    }
    let emphasisRange = full.range(of: "emphasized phrase")
    if emphasisRange.location != NSNotFound {
      text.addAttributes([
        .font: UIFont.preferredFont(forTextStyle: .headline),
        .foregroundColor: UIColor.systemPurple,
      ], range: emphasisRange)
    }
    return text
  }

  static func makeBodyParagraph(font: UIFont = .preferredFont(forTextStyle: .body), color: UIColor = .label) -> NSAttributedString {
    NSAttributedString(string: plainParagraph, attributes: [
      .font: font,
      .foregroundColor: color,
    ])
  }

  static func configureBodyLabel(_ label: UILabel) {
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
  }
}

// MARK: - Scroll embedding

extension UIViewController {
  func fk_expandableText_embedInScroll(_ contentStack: UIStackView) {
    let scrollView = UIScrollView()
    let containerView = UIView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    containerView.translatesAutoresizingMaskIntoConstraints = false
    contentStack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(containerView)
    containerView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      contentStack.topAnchor.constraint(equalTo: containerView.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }
}

// MARK: - Base scenario chrome

class FKExpandableTextExampleBaseViewController: UIViewController {
  private static let cardContentViewTag = 0xF0E711

  let contentStackView = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    contentStackView.axis = .vertical
    contentStackView.spacing = 20
    contentStackView.translatesAutoresizingMaskIntoConstraints = false
    fk_expandableText_embedInScroll(contentStackView)
  }

  func makeCard(title: String, subtitle: String? = nil) -> UIView {
    let card = UIView()
    card.backgroundColor = .secondarySystemBackground
    card.layer.cornerRadius = 16
    card.layer.cornerCurve = .continuous
    card.translatesAutoresizingMaskIntoConstraints = false

    let titleLabel = UILabel()
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.text = title
    titleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    if let subtitle {
      let subtitleLabel = UILabel()
      subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
      subtitleLabel.textColor = .secondaryLabel
      subtitleLabel.numberOfLines = 0
      subtitleLabel.text = subtitle
      stack.addArrangedSubview(subtitleLabel)
    }

    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.tag = Self.cardContentViewTag
    stack.addArrangedSubview(contentView)

    card.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
    ])
    return card
  }

  func cardContentView(from card: UIView) -> UIView {
    guard let slot = card.viewWithTag(Self.cardContentViewTag) else {
      assertionFailure("Card is missing the tagged content slot.")
      return card
    }
    return slot
  }

  /// Resolves constraints so `FKExpandableText` width measurement matches on-screen layout, then runs `work`.
  func fk_expandableText_runWhenLaidOut(_ work: () -> Void) {
    view.layoutIfNeeded()
    work()
  }
}
