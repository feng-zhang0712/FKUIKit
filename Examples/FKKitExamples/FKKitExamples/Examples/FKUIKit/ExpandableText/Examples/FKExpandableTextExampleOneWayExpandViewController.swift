import FKUIKit
import UIKit

final class FKExpandableTextExampleOneWayExpandViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "One-way expand"

    let card = makeCard(
      title: "Stays expanded",
      subtitle: "`oneWayExpand: true` removes collapse."
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
    let configuration = FKExpandableTextConfiguration(oneWayExpand: true)
    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph(), configuration: configuration)
    }
  }
}
