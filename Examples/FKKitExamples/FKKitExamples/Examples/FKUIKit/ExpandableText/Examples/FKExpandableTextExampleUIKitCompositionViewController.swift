import FKUIKit
import UIKit

final class FKExpandableTextExampleUIKitCompositionViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()
  private let textView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIKit composition"

    let labelCard = makeCard(
      title: "UILabel",
      subtitle: "`fk_setExpandableText`"
    )
    let labelSlot = cardContentView(from: labelCard)
    FKExpandableTextExampleSupport.configureBodyLabel(label)
    labelSlot.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: labelSlot.topAnchor),
      label.leadingAnchor.constraint(equalTo: labelSlot.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: labelSlot.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: labelSlot.bottomAnchor),
    ])

    let textCard = makeCard(
      title: "UITextView",
      subtitle: "`FKExpandableText.attach`"
    )
    let textSlot = cardContentView(from: textCard)
    textView.backgroundColor = .clear
    textView.font = .preferredFont(forTextStyle: .body)
    textView.textColor = .label
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    textSlot.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: textSlot.topAnchor),
      textView.leadingAnchor.constraint(equalTo: textSlot.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: textSlot.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: textSlot.bottomAnchor),
      textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 90),
    ])

    contentStackView.addArrangedSubview(labelCard)
    contentStackView.addArrangedSubview(textCard)

    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph())
      _ = FKExpandableText.attach(
        to: textView,
        attributedText: FKExpandableTextExampleSupport.attributedRichText()
      )
    }
  }
}
