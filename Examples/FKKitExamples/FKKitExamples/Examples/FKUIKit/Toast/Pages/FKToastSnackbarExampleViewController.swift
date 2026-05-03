import UIKit
import FKUIKit

final class FKToastSnackbarExampleViewController: FKToastExampleBaseViewController {
  private let announcementSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Snackbar"

    announcementSwitch.isOn = true
    let toggleRow = UIStackView()
    toggleRow.axis = .horizontal
    toggleRow.alignment = .center
    toggleRow.spacing = 8
    let toggleLabel = UILabel()
    toggleLabel.text = "Enable VoiceOver announcement"
    toggleLabel.font = .preferredFont(forTextStyle: .subheadline)
    toggleLabel.adjustsFontForContentSizeCategory = true
    toggleRow.addArrangedSubview(toggleLabel)
    toggleRow.addArrangedSubview(announcementSwitch)

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(toggleRow)
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Show Action Snackbar") { [weak self] in
        FKToastExamplePlaybook.showActionSnackbarExample(announcementEnabled: self?.announcementSwitch.isOn ?? true)
      },
      FKToastExampleUI.button("Clear Current") { FKToast.clearAll(animated: true) },
    ]))

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Interactive Snackbar",
        description: "Shows primary and secondary actions, swipe dismiss, accessibility labels, and announcement on/off control.",
        body: actions
      )
    )
  }
}
