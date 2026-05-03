import FKUIKit
import UIKit

final class FKExpandableTextExampleFullTextAreaViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tap full text area"

    let card = makeCard(
      title: "Whole label toggles",
      subtitle: "`interactionMode: .fullTextArea`"
    )
    let slot = cardContentView(from: card)
    FKExpandableTextExampleSupport.configureBodyLabel(label)

    slot.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: slot.topAnchor),
      label.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
    let configuration = FKExpandableTextConfiguration(interactionMode: .fullTextArea)
    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph(), configuration: configuration)
    }
  }
}
