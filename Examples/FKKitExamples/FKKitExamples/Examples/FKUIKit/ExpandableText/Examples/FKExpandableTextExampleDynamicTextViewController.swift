import FKUIKit
import UIKit

final class FKExpandableTextExampleDynamicTextViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()
  private let infoLabel = UILabel()
  private var useLongText = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic text"

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle",
      style: .plain,
      target: self,
      action: #selector(toggleText)
    )

    let card = makeCard(
      title: "Runtime replacement",
      subtitle: "Switches short/long copy; truncation recomputes."
    )
    let slot = cardContentView(from: card)
    FKExpandableTextExampleSupport.configureBodyLabel(label)

    infoLabel.numberOfLines = 0
    infoLabel.font = .preferredFont(forTextStyle: .footnote)
    infoLabel.textColor = .secondaryLabel
    infoLabel.text = "Current: short"
    infoLabel.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [infoLabel, label])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    slot.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: slot.topAnchor),
      stack.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
    fk_expandableText_runWhenLaidOut {
      applyCurrentText()
    }
  }

  @objc private func toggleText() {
    useLongText.toggle()
    applyCurrentText()
  }

  private func applyCurrentText() {
    view.layoutIfNeeded()
    let text = useLongText ? FKExpandableTextExampleSupport.dynamicLongText : FKExpandableTextExampleSupport.dynamicShortText
    infoLabel.text = useLongText ? "Current: long" : "Current: short"
    label.fk_setExpandableText(text)
  }
}
