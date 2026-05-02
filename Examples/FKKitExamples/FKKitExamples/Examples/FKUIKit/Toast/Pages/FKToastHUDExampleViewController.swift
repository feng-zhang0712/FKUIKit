import UIKit
import FKUIKit

final class FKToastHUDExampleViewController: FKToastExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "HUD"

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Loading (Blocking)") { FKToastExamplePlaybook.showHUDLoading(blocking: true) },
      FKToastExampleUI.button("Loading (Passthrough)") { FKToastExamplePlaybook.showHUDLoading(blocking: false) },
    ]))
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Progress 0→100") { FKToastExamplePlaybook.showHUDProgress() },
      FKToastExampleUI.button("Success/Failure Icons") { FKToastExamplePlaybook.showHUDEndStates() },
    ]))
    actions.addArrangedSubview(FKToastExampleUI.button("Live Update Same HUD Instance") {
      FKToastExamplePlaybook.showLiveHUDProgress()
    })
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Manual Dismiss") { FKToast.clearAll(animated: true) },
      FKToastExampleUI.button("Timeout Fallback") { FKHUD.showLoading("Will auto timeout in 3s", interceptTouches: true, timeout: 3) },
    ]))

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "HUD Capabilities",
        description: "Validate loading spinner, determinate progress simulation, blocking/non-blocking touch behavior, explicit dismiss, and timeout safety fallback.",
        body: actions
      )
    )
  }
}
