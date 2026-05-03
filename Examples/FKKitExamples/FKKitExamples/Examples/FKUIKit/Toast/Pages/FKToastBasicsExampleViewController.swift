import UIKit
import FKUIKit

final class FKToastBasicsExampleViewController: FKToastExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic Toast"

    let sectionOne = UIStackView()
    sectionOne.axis = .vertical
    sectionOne.spacing = 8
    sectionOne.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Top/Center/Bottom") { FKToastExamplePlaybook.showBasicPlacementAndStyle() },
      FKToastExampleUI.button("Long Multiline") { FKToastExamplePlaybook.showLongMultilineToast() },
    ]))
    sectionOne.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Custom Icon") { FKToastExamplePlaybook.showCustomIconToast() },
      FKToastExampleUI.button("Custom View") { FKToastExamplePlaybook.showCustomViewToast() },
    ]))
    sectionOne.addArrangedSubview(FKToastExampleUI.button("Placement Insets (Nav/Tab Aware)") {
      FKToastExamplePlaybook.showPlacementInsetsExample()
    })
    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Basic Coverage",
        description: "Verify placement rules, multiline wrapping, semantic style, icon override, custom UIView content, and nav/tab-aware spacing.",
        body: sectionOne
      )
    )
  }
}
