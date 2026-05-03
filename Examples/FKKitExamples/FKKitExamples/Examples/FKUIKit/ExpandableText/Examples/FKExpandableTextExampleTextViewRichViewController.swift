import FKUIKit
import UIKit

final class FKExpandableTextExampleTextViewRichViewController: FKExpandableTextExampleBaseViewController {
  private let textView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITextView — rich text"

    let card = makeCard(
      title: "Attributed string + URL link",
      subtitle: "`FKExpandableText.attach` keeps link handling."
    )
    let slot = cardContentView(from: card)

    textView.backgroundColor = .clear
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textColor = .label
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]

    slot.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: slot.topAnchor),
      textView.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
    ])

    contentStackView.addArrangedSubview(card)
    fk_expandableText_runWhenLaidOut {
      let controller = FKExpandableText.attach(
        to: textView,
        attributedText: FKExpandableTextExampleSupport.attributedRichText()
      )
      controller.onLinkTapped = { _ in }
    }
  }
}
