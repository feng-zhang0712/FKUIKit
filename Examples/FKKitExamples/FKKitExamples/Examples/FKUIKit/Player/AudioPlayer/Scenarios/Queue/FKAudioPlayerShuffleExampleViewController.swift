import FKUIKit
import UIKit

/// Shuffle queue order via ``FKAudioQueueMode/shuffle``.
@MainActor
final class FKAudioPlayerShuffleExampleViewController: FKAudioPlayerExampleShellViewController {

  private let modeLabel = UILabel()

  override func viewDidLoad() {
    title = "Shuffle"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Shuffle order is rebuilt when the mode changes. Use next/previous to walk the shuffled path."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    modeLabel.font = .preferredFont(forTextStyle: .footnote)
    modeLabel.textColor = .secondaryLabel

    let reshuffle = FKAudioPlayerExampleLayout.makePrimaryButton("Reshuffle order", action: UIAction { [weak self] _ in
      guard let self else { return }
      self.player.queue.mode = .shuffle
      self.player.applyLoopModeFromQueue()
      self.refreshModeLabel()
    })
    let stack = UIStackView(arrangedSubviews: [modeLabel, reshuffle])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
    player.queue.mode = .shuffle
    player.applyLoopModeFromQueue()
    refreshModeLabel()
  }

  private func refreshModeLabel() {
    modeLabel.text = "Now playing: \(player.currentItem?.title ?? "—")"
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    refreshModeLabel()
  }
}
