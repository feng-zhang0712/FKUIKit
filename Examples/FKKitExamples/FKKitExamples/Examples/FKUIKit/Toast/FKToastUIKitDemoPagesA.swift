import UIKit
import FKUIKit

final class FKToastBasicsDemoViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic Toast"

    let sectionOne = UIStackView()
    sectionOne.axis = .vertical
    sectionOne.spacing = 8
    sectionOne.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Top/Center/Bottom") { FKToastDemoPlaybook.showBasicPlacementAndStyle() },
      FKToastDemoUI.button("Long Multiline") { FKToastDemoPlaybook.showLongMultilineToast() },
    ]))
    sectionOne.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Custom Icon") { FKToastDemoPlaybook.showCustomIconToast() },
      FKToastDemoUI.button("Custom View") { FKToastDemoPlaybook.showCustomViewToast() },
    ]))
    sectionOne.addArrangedSubview(FKToastDemoUI.button("Placement Insets (Nav/Tab Aware)") {
      FKToastDemoPlaybook.showPlacementInsetsDemo()
    })
    contentStack.addArrangedSubview(
      FKToastDemoUI.section(
        title: "Basic Coverage",
        description: "Verify placement rules, multiline wrapping, semantic style, icon override, custom UIView content, and nav/tab-aware spacing.",
        body: sectionOne
      )
    )
  }
}

final class FKToastQueueStrategyDemoViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Queue & Strategy"

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Burst Queue") { FKToastDemoPlaybook.burstQueueDemo() },
      FKToastDemoUI.button("Dedupe / Coalesce") { FKToastDemoPlaybook.dedupeCoalesceDemo() },
    ]))
    actions.addArrangedSubview(FKToastDemoUI.button("Priority Interrupt Compare") {
      FKToastDemoPlaybook.interruptionComparison()
    })

    contentStack.addArrangedSubview(
      FKToastDemoUI.section(
        title: "Queue Policies",
        description: "Demonstrates sequential queue rendering, duplicate merge strategy, and priority interruption with restore/no-restore behavior.",
        body: actions
      )
    )
  }
}

final class FKToastHUDDemoViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "HUD"

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Loading (Blocking)") { FKToastDemoPlaybook.showHUDLoading(blocking: true) },
      FKToastDemoUI.button("Loading (Passthrough)") { FKToastDemoPlaybook.showHUDLoading(blocking: false) },
    ]))
    actions.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Progress 0→100") { FKToastDemoPlaybook.showHUDProgress() },
      FKToastDemoUI.button("Success/Failure Icons") { FKToastDemoPlaybook.showHUDEndStates() },
    ]))
    actions.addArrangedSubview(FKToastDemoUI.button("Live Update Same HUD Instance") {
      FKToastDemoPlaybook.showLiveHUDProgress()
    })
    actions.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Manual Dismiss") { FKToast.clearAll(animated: true) },
      FKToastDemoUI.button("Timeout Fallback") { FKHUD.showLoading("Will auto timeout in 3s", interceptTouches: true, timeout: 3) },
    ]))

    contentStack.addArrangedSubview(
      FKToastDemoUI.section(
        title: "HUD Capabilities",
        description: "Validate loading spinner, determinate progress simulation, blocking/non-blocking touch behavior, explicit dismiss, and timeout safety fallback.",
        body: actions
      )
    )
  }
}
