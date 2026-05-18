import FKUIKit
import UIKit

/// Reads ``FKAudioPlaybackSnapshot`` for Watch complications and widgets.
@MainActor
final class FKAudioPlayerWatchWidgetExampleViewController: FKAudioPlayerExampleShellViewController {

  private let snapshotLabel = UILabel()
  private var refreshTimer: Timer?

  override func viewDidLoad() {
    title = "Watch / Widget"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "`FKAudioPlayer` conforms to `FKAudioWatchPlaybackProviding` and `FKAudioWidgetPlaybackProviding`."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    snapshotLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    snapshotLabel.textColor = .label
    snapshotLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [snapshotLabel])
    stack.axis = .vertical
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
    refreshSnapshot()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.refreshSnapshot()
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  private func refreshSnapshot() {
    let snap = player.currentSnapshot()
    snapshotLabel.text = """
    itemID: \(snap.itemID ?? "nil")
    title: \(snap.title ?? "—")
    artist: \(snap.artist ?? "—")
    playing: \(snap.isPlaying)
    time: \(String(format: "%.1f", snap.currentTime)) / \(String(format: "%.1f", snap.duration))
    """
  }

  override func audioPlayer(_ player: FKAudioPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {
    super.audioPlayer(player, didUpdateTime: current, duration: duration)
    refreshSnapshot()
  }
}
