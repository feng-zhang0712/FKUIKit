import FKUIKit
import UIKit

/// Records played item IDs through ``FKAudioPlayHistoryStore``.
@MainActor
final class FKAudioPlayerHistoryExampleViewController: FKAudioPlayerExampleShellViewController {

  private let historyStore = FKAudioInMemoryPlayHistoryStore()
  private let historyLabel = UILabel()

  override func viewDidLoad() {
    title = "Play history"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Uses `FKAudioInMemoryPlayHistoryStore` so recent IDs are deterministic in the demo."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    historyLabel.font = .preferredFont(forTextStyle: .footnote)
    historyLabel.textColor = .secondaryLabel
    historyLabel.numberOfLines = 0

    let track1 = FKAudioPlayerExampleLayout.makePrimaryButton("Play track 1", action: UIAction { [weak self] _ in
      self?.play(FKAudioPlayerExampleCatalog.trackOne())
    })
    let track2 = FKAudioPlayerExampleLayout.makeSecondaryButton("Play track 2", action: UIAction { [weak self] _ in
      self?.play(FKAudioPlayerExampleCatalog.trackTwo())
    })
    let track3 = FKAudioPlayerExampleLayout.makeSecondaryButton("Play track 3", action: UIAction { [weak self] _ in
      self?.play(FKAudioPlayerExampleCatalog.trackThree())
    })
    let stack = UIStackView(arrangedSubviews: [historyLabel, track1, track2, track3])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.playHistoryStore = historyStore
    refreshHistory()
  }

  private func play(_ item: FKAudioItem) {
    player.load(item, autoPlay: true)
    refreshHistory()
  }

  private func refreshHistory() {
    let recent = historyStore.recentItemIDs(limit: 5)
    historyLabel.text = recent.isEmpty
      ? "No history yet — play a track."
      : "Recent IDs:\n" + recent.joined(separator: "\n")
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    refreshHistory()
  }
}
