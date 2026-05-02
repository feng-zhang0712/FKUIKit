import UIKit
import FKUIKit

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
