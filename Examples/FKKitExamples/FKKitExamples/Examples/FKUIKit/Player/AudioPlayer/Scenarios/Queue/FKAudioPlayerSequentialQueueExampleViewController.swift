import FKUIKit
import UIKit

/// Sequential queue with next/previous navigation.
@MainActor
final class FKAudioPlayerSequentialQueueExampleViewController: FKAudioPlayerExampleShellViewController {

  private let modeLabel = UILabel()

  override func viewDidLoad() {
    title = "Sequential queue"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Three MP3 tracks in `.sequential` mode. Playback stops after the last item."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    modeLabel.font = .preferredFont(forTextStyle: .footnote)
    modeLabel.textColor = .secondaryLabel
    modeLabel.text = "Mode: sequential"

    let next = FKAudioPlayerExampleLayout.makePrimaryButton("Play next", action: UIAction { [weak self] _ in
      self?.player.playNext()
      self?.refreshModeLabel()
    })
    let previous = FKAudioPlayerExampleLayout.makeSecondaryButton("Play previous", action: UIAction { [weak self] _ in
      self?.player.playPrevious()
      self?.refreshModeLabel()
    })
    let stack = UIStackView(arrangedSubviews: [modeLabel, previous, next])
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
    player.queue.mode = .sequential
    player.applyLoopModeFromQueue()
    refreshModeLabel()
  }

  private func refreshModeLabel() {
    let index = player.currentIndex.map(String.init) ?? "—"
    modeLabel.text = "Mode: sequential · index \(index) · \(player.currentItem?.title ?? "—")"
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    refreshModeLabel()
  }
}
