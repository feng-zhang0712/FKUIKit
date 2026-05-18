import FKUIKit
import UIKit

/// Cycles repeat-one and repeat-all queue modes.
@MainActor
final class FKAudioPlayerRepeatModesExampleViewController: FKAudioPlayerExampleShellViewController {

  private let modeLabel = UILabel()

  override func viewDidLoad() {
    title = "Repeat modes"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Repeat-all loads a Core playlist and delegates skip commands to the coordinator."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    modeLabel.font = .preferredFont(forTextStyle: .footnote)
    modeLabel.textColor = .secondaryLabel

    let repeatOne = FKAudioPlayerExampleLayout.makePrimaryButton("Repeat one", action: UIAction { [weak self] _ in
      self?.setMode(.repeatOne)
    })
    let repeatAll = FKAudioPlayerExampleLayout.makeSecondaryButton("Repeat all", action: UIAction { [weak self] _ in
      self?.setMode(.repeatAll)
    })
    let stack = UIStackView(arrangedSubviews: [modeLabel, repeatOne, repeatAll])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    setMode(.repeatAll)
    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
  }

  private func setMode(_ mode: FKAudioQueueMode) {
    player.queue.mode = mode
    player.applyLoopModeFromQueue()
    if mode == .repeatAll {
      player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: player.state == .playing)
    }
    let hint = mode == .repeatAll ? "Core playlist navigation" : "Single-track loop"
    modeLabel.text = "Mode: \(mode.rawValue) · \(hint)"
  }
}
