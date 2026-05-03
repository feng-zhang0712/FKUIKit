import FKUIKit
import UIKit

final class FKExpandableTextExampleLabelBasicViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UILabel — basic"

    let card = makeCard(
      title: "Plain body + default actions",
      subtitle: "Uses `fk_setExpandableText` with library defaults."
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
    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph())
    }
  }
}
