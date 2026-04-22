import FKUIKit
import UIKit
#if canImport(SwiftUI)
  import SwiftUI
#endif

/// Entry list for FKExpandableText demos.
///
/// This hub is intentionally simple and copy-ready:
/// - each row opens a dedicated scenario controller
/// - every scenario focuses on one usage pattern
/// - all examples can be dropped into a project without extra setup
final class FKExpandableTextExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let makeViewController: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "UILabel Basic Expand/Collapse",
      subtitle: "Plain text with default action and animation",
      makeViewController: { FKExpandableTextLabelBasicDemoViewController() }
    ),
    Row(
      title: "UITextView Rich Text + Links",
      subtitle: "Supports attributed text and link interaction",
      makeViewController: { FKExpandableTextTextViewRichTextDemoViewController() }
    ),
    Row(
      title: "Custom Collapse Line Limit",
      subtitle: "Specify visible lines in collapsed state",
      makeViewController: { FKExpandableTextCustomLineLimitDemoViewController() }
    ),
    Row(
      title: "Custom Action Style",
      subtitle: "Customize action text, color, font, and style",
      makeViewController: { FKExpandableTextCustomButtonStyleDemoViewController() }
    ),
    Row(
      title: "One-way Expand",
      subtitle: "oneWayExpand = true",
      makeViewController: { FKExpandableTextOneWayExpandDemoViewController() }
    ),
    Row(
      title: "Tap Whole Text Area",
      subtitle: "interactionMode = .fullTextArea",
      makeViewController: { FKExpandableTextFullTextAreaTapDemoViewController() }
    ),
    Row(
      title: "Dynamic Text Updates",
      subtitle: "Replace content at runtime and relayout automatically",
      makeViewController: { FKExpandableTextDynamicUpdateDemoViewController() }
    ),
    Row(
      title: "Custom Animation",
      subtitle: "curve / spring / none",
      makeViewController: { FKExpandableTextCustomAnimationDemoViewController() }
    ),
    Row(
      title: "UIKit Integration",
      subtitle: "Demonstrates UILabel and UITextView in one screen",
      makeViewController: { FKExpandableTextUIKitIntegrationDemoViewController() }
    ),
    Row(
      title: "SwiftUI Integration",
      subtitle: "Use via UIViewRepresentable wrapper in SwiftUI",
      makeViewController: { FKExpandableTextSwiftUIHostViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKExpandableText"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].makeViewController(), animated: true)
  }
}

// MARK: - Shared demo helpers

private enum FKExpandableTextDemoData {
  static let plainParagraph = "FKExpandableText truncates long content automatically and lets users toggle between collapsed and expanded states with an action. It works well for article summaries, user bios, review snippets, and message previews."

  static let dynamicShortText = "This is the short text version. Tap the button to switch to a longer one."

  static let dynamicLongText = "This is a longer dynamic text sample. It shows that after runtime text updates, the component recalculates truncation, relayouts correctly, and keeps expand/collapse interaction available. This pattern is useful for async API content, refreshed summaries, and live preview after user edits."

  static func attributedRichText() -> NSAttributedString {
    let text = NSMutableAttributedString(
      string: "This is a rich text sample with a link: https://www.fkkit.com and an emphasized phrase. Link interaction is handled by UITextView while expand/collapse action remains available.",
      attributes: [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.label,
      ]
    )

    let full = text.string as NSString
    let urlRange = full.range(of: "https://www.fkkit.com")
    if urlRange.location != NSNotFound {
      text.addAttributes([
        .link: URL(string: "https://www.fkkit.com")!,
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

  static func makeParagraph(font: UIFont = .preferredFont(forTextStyle: .body), color: UIColor = .label) -> NSAttributedString {
    NSAttributedString(string: plainParagraph, attributes: [
      .font: font,
      .foregroundColor: color,
    ])
  }
}

private extension UIViewController {
  func fk_embedContent(in scrollView: UIScrollView, inside container: UIView, using contentView: UIView) {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    container.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(container)
    container.addSubview(contentView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      container.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      container.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      contentView.topAnchor.constraint(equalTo: container.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }
}

// MARK: - Base content view controller

private class FKExpandableTextBaseDemoViewController: UIViewController {
  private static let cardContentViewTag = 0xF0E711

  let scrollView = UIScrollView()
  let containerView = UIView()
  let contentStackView = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    contentStackView.axis = .vertical
    contentStackView.spacing = 20
    contentStackView.translatesAutoresizingMaskIntoConstraints = false

    fk_embedContent(in: scrollView, inside: containerView, using: contentStackView)
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
    if let contentView = card.viewWithTag(Self.cardContentViewTag) {
      return contentView
    }
    assertionFailure("Card content view missing.")
    return card
  }
}

// MARK: - 1. UILabel basic demo

private final class FKExpandableTextLabelBasicDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UILabel Basic Demo"

    let card = makeCard(
      title: "Basic UILabel Expand/Collapse",
      subtitle: "Good for plain text summaries. Tap action to toggle."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph())

    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .footnote)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Note: This example uses default configuration."

    contentStackView.addArrangedSubview(card)
    contentStackView.addArrangedSubview(note)
    note.setContentCompressionResistancePriority(.required, for: .vertical)
  }
}

// MARK: - 2. UITextView rich text demo

private final class FKExpandableTextTextViewRichTextDemoViewController: FKExpandableTextBaseDemoViewController {
  private let textView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITextView Rich Text Demo"

    let card = makeCard(
      title: "Basic UITextView Rich Text + Links",
      subtitle: "Supports attributed text, link taps, and expand/collapse."
    )
    let contentView = cardContentView(from: card)

    textView.backgroundColor = .clear
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textColor = .label
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]

    let controller = FKExpandableText.apply(to: textView, text: FKExpandableTextDemoData.attributedRichText())
    controller.onLinkTapped = { url in
      print("Link tapped: \(url)")
    }

    contentView.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: contentView.topAnchor),
      textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
    ])

    contentStackView.addArrangedSubview(card)
  }
}

// MARK: - 3. Custom line count demo

private final class FKExpandableTextCustomLineLimitDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Line Limit"

    let card = makeCard(
      title: "Custom collapseRule",
      subtitle: "Configured to show 2 lines when collapsed."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    let configuration = FKExpandableTextConfiguration(collapseRule: .lines(2))
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: configuration)

    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
  }
}

// MARK: - 4. Custom button style demo

private final class FKExpandableTextCustomButtonStyleDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Action Style"

    let card = makeCard(
      title: "Custom action text, color, and style",
      subtitle: "Customize expand/collapse labels, fonts, colors, and truncation token."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    let configuration = FKExpandableTextConfiguration(
      truncationToken: NSAttributedString(
        string: "… ",
        attributes: [
          .foregroundColor: UIColor.systemOrange,
          .font: UIFont.preferredFont(forTextStyle: .body),
        ]
      ),
      expandActionText: NSAttributedString(
        string: "Read more",
        attributes: [
          .foregroundColor: UIColor.systemRed,
          .font: UIFont.systemFont(ofSize: 16, weight: .bold),
        ]
      ),
      collapseActionText: NSAttributedString(
        string: "Collapse",
        attributes: [
          .foregroundColor: UIColor.systemGreen,
          .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
        ]
      ),
      collapseRule: .lines(3),
      buttonPlacement: .trailingBottom,
      interactionMode: .buttonOnly,
      oneWayExpand: false,
      animation: .curve(duration: 0.2, options: [.curveEaseInOut])
    )

    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: configuration)

    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
  }
}

// MARK: - 5. One-way expand demo

private final class FKExpandableTextOneWayExpandDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "One-way Expand"

    let card = makeCard(
      title: "oneWayExpand = true",
      subtitle: "After first expansion, it stays expanded and cannot collapse."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    let configuration = FKExpandableTextConfiguration(oneWayExpand: true)
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: configuration)

    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
  }
}

// MARK: - 6. Full text area tap demo

private final class FKExpandableTextFullTextAreaTapDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tap Full Text Area"

    let card = makeCard(
      title: "interactionMode = .fullTextArea",
      subtitle: "Tapping anywhere in text toggles state."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    let configuration = FKExpandableTextConfiguration(interactionMode: .fullTextArea)
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: configuration)

    contentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
  }
}

// MARK: - 7. Dynamic update demo

private final class FKExpandableTextDynamicUpdateDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()
  private let infoLabel = UILabel()
  private var useLongText = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic Text Update"

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle Text",
      style: .plain,
      target: self,
      action: #selector(toggleText)
    )

    let card = makeCard(
      title: "Runtime Text Replacement",
      subtitle: "Tap top-right button to switch short/long text."
    )
    let contentView = cardContentView(from: card)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    infoLabel.numberOfLines = 0
    infoLabel.font = .preferredFont(forTextStyle: .footnote)
    infoLabel.textColor = .secondaryLabel
    infoLabel.text = "Current content: Short text"
    infoLabel.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [infoLabel, label])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
    applyCurrentText()
  }

  @objc private func toggleText() {
    useLongText.toggle()
    applyCurrentText()
  }

  private func applyCurrentText() {
    let text = useLongText ? FKExpandableTextDemoData.dynamicLongText : FKExpandableTextDemoData.dynamicShortText
    infoLabel.text = useLongText ? "Current content: Long text" : "Current content: Short text"
    label.fk_setExpandableText(text)
  }
}

// MARK: - 8. Custom animation demo

private final class FKExpandableTextCustomAnimationDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()
  private let segmentedControl = UISegmentedControl(items: ["Curve", "Spring", "None"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Animation"

    let card = makeCard(
      title: "Switch Animation Type",
      subtitle: "Demonstrates curve, spring, and no animation."
    )
    let contentView = cardContentView(from: card)

    segmentedControl.selectedSegmentIndex = 0
    segmentedControl.addTarget(self, action: #selector(animationChanged), for: .valueChanged)
    segmentedControl.translatesAutoresizingMaskIntoConstraints = false

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false

    let wrapper = UIStackView(arrangedSubviews: [segmentedControl, label])
    wrapper.axis = .vertical
    wrapper.spacing = 12
    wrapper.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(wrapper)
    NSLayoutConstraint.activate([
      wrapper.topAnchor.constraint(equalTo: contentView.topAnchor),
      wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      wrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      wrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
    applyConfiguration()
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: currentConfiguration())
  }

  @objc private func animationChanged() {
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph(), configuration: currentConfiguration())
  }

  private func currentConfiguration() -> FKExpandableTextConfiguration {
    switch segmentedControl.selectedSegmentIndex {
    case 1:
      return FKExpandableTextConfiguration(animation: .spring(duration: 0.4, dampingRatio: 0.75, velocity: 0.2, options: [.curveEaseInOut]))
    case 2:
      return FKExpandableTextConfiguration(animation: .none)
    default:
      return FKExpandableTextConfiguration(animation: .curve(duration: 0.25, options: [.curveEaseInOut]))
    }
  }

  private func applyConfiguration() {
    // Reserved for future customization if you want to style the control itself.
  }
}

// MARK: - 9. UIKit integration demo

private final class FKExpandableTextUIKitIntegrationDemoViewController: FKExpandableTextBaseDemoViewController {
  private let label = UILabel()
  private let textView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIKit Integration"

    let labelCard = makeCard(
      title: "UILabel Integration",
      subtitle: "Directly use `fk_setExpandableText`."
    )
    let labelContentView = cardContentView(from: labelCard)

    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
    label.fk_setExpandableText(FKExpandableTextDemoData.makeParagraph())

    labelContentView.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: labelContentView.topAnchor),
      label.leadingAnchor.constraint(equalTo: labelContentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: labelContentView.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: labelContentView.bottomAnchor),
    ])

    let textViewCard = makeCard(
      title: "UITextView Integration",
      subtitle: "Directly use `FKExpandableText.apply(to:text:)`."
    )
    let textViewContentView = cardContentView(from: textViewCard)

    textView.backgroundColor = .clear
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textColor = .label
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    let controller = FKExpandableText.apply(to: textView, text: FKExpandableTextDemoData.attributedRichText())
    controller.onLinkTapped = { url in
      print("UIKit integration link tapped: \(url)")
    }

    textViewContentView.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: textViewContentView.topAnchor),
      textView.leadingAnchor.constraint(equalTo: textViewContentView.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: textViewContentView.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: textViewContentView.bottomAnchor),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90),
    ])

    contentStackView.addArrangedSubview(labelCard)
    contentStackView.addArrangedSubview(textViewCard)
  }
}

#if canImport(SwiftUI)

  // MARK: - 10. SwiftUI integration demo

  struct FKExpandableTextSwiftUIDemoView: View {
    @State private var isExpanded = false

    private let text = FKExpandableTextDemoData.attributedRichText()

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("SwiftUI Integration Demo")
            .font(.title2.weight(.semibold))

          Text("Use `FKExpandableTextView` to wrap UIKit behavior directly in SwiftUI.")
            .font(.subheadline)
            .foregroundColor(.secondary)

          FKExpandableTextView(
            text: text,
            configuration: FKExpandableTextConfiguration(
              collapseRule: .lines(3),
              interactionMode: .buttonOnly,
              animation: .spring(duration: 0.35, dampingRatio: 0.8, velocity: 0.2, options: [.curveEaseInOut])
            ),
            isExpanded: $isExpanded,
            onStateChanged: { state in
              print("SwiftUI state changed: \(state)")
            },
            onLinkTapped: { url in
              print("SwiftUI link tapped: \(url)")
            }
          )
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(16)

          Button(isExpanded ? "Collapse" : "Expand") {
            isExpanded.toggle()
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
      }
      .navigationTitle("SwiftUI Integration")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  final class FKExpandableTextSwiftUIHostViewController: UIViewController {
    override func viewDidLoad() {
      super.viewDidLoad()
      title = "SwiftUI Integration"
      view.backgroundColor = .systemBackground

      let host = UIHostingController(rootView: FKExpandableTextSwiftUIDemoView())
      addChild(host)
      host.view.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(host.view)

      NSLayoutConstraint.activate([
        host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])

      host.didMove(toParent: self)
    }
  }
#endif
