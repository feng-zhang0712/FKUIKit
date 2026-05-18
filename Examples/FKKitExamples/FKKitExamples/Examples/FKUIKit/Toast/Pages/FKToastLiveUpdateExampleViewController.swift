import FKUIKit
import UIKit

/// Compares sequential toast queueing with immediate in-place replacement.
final class FKToastLiveUpdateExampleViewController: FKToastExampleBaseViewController {

  private var liveHandle: FKToastHandle?
  private let modes = ["Sequential", "Shuffle", "Repeat all", "Repeat one"]
  private var modeIndex = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Live Update"

    let description = UILabel()
    description.numberOfLines = 0
    description.font = .preferredFont(forTextStyle: .footnote)
    description.textColor = .secondaryLabel
    description.text =
      "Sequential uses the default queue. Replace active swaps message and style on the visible toast without waiting for dismiss."

    let sequential = FKToastExampleUI.button("Burst (sequential)") { [weak self] in
      self?.burstSequential()
    }
    let replace = FKToastExampleUI.button("Burst (replace active)") { [weak self] in
      self?.burstReplaceActive()
    }
    let handle = FKToastExampleUI.button("Handle + update()") { [weak self] in
      self?.cycleHandleUpdate()
    }

    let actions = UIStackView(arrangedSubviews: [sequential, replace, handle])
    actions.axis = .vertical
    actions.spacing = 8

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Presentation strategy",
        description: "Tap quickly to see the difference between waiting for dismiss and immediate replacement.",
        body: actions
      )
    )
    contentStack.insertArrangedSubview(description, at: 0)
  }

  private func burstSequential() {
    for index in 1...5 {
      FKToast.show(
        "Sequential #\(index)",
        style: index.isMultiple(of: 2) ? .info : .success,
        presentationStrategy: .sequential
      )
    }
  }

  private func burstReplaceActive() {
    for index in 1...5 {
      FKToast.show(
        "Replace #\(index)",
        style: index.isMultiple(of: 2) ? .warning : .info,
        presentationStrategy: .replaceActive
      )
    }
  }

  private func cycleHandleUpdate() {
    modeIndex = (modeIndex + 1) % modes.count
    let label = modes[modeIndex]
    liveHandle = FKToast.showOrUpdate(
      "Queue mode: \(label)",
      handle: liveHandle,
      style: .info,
      presentationStrategy: .replaceActive
    )
  }
}
