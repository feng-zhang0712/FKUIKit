import FKUIKit
import UIKit

final class FKExpandableTextExampleActionStyleViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom action styling"

    let card = makeCard(
      title: "Token + action fonts",
      subtitle: "`buttonPlacement: .trailingBottom`"
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
      interactionMode: .buttonOnly
    )
    fk_expandableText_runWhenLaidOut {
      label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph(), configuration: configuration)
    }
  }
}
