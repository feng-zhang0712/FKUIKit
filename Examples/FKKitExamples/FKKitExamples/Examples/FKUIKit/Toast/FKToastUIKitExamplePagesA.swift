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

final class FKToastQueueStrategyExampleViewController: FKToastExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Queue & Strategy"

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Burst Queue") { FKToastExamplePlaybook.burstQueueExample() },
      FKToastExampleUI.button("Dedupe / Coalesce") { FKToastExamplePlaybook.dedupeCoalesceExample() },
    ]))
    actions.addArrangedSubview(FKToastExampleUI.button("Priority Interrupt Compare") {
      FKToastExamplePlaybook.interruptionComparison()
    })

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Queue Policies",
        description: "Demonstrates sequential queue rendering, duplicate merge strategy, and priority interruption with restore/no-restore behavior.",
        body: actions
      )
    )
  }
}

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

