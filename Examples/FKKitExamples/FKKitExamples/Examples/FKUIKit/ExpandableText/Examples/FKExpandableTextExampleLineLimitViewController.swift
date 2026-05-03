import FKUIKit
import UIKit

final class FKExpandableTextExampleLineLimitViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom line limit"

    let card = makeCard(title: "Two visible lines", subtitle: "`collapseRule: .lines(2)`")
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
    let configuration = FKExpandableTextConfiguration(collapseRule: .lines(2))
    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph(), configuration: configuration)
    }
  }
}
