import FKUIKit
import UIKit

/// Demonstrates ``FKVideoMiniPlayerView`` floating chrome.
@MainActor
final class FKVideoPlayerMiniPlayerExampleViewController: FKVideoPlayerExampleShellViewController {

  private let miniPlayer = FKVideoMiniPlayerView()

  override func viewDidLoad() {
    title = "Mini player"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Main surface above; compact mini player docked to the safe area bottom."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    miniPlayer.translatesAutoresizingMaskIntoConstraints = false
    miniPlayer.onExpand = { }
    miniPlayer.onClose = { [weak self] in
      self?.player.stop()
    }
    view.addSubview(miniPlayer)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      miniPlayer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      miniPlayer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      miniPlayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      miniPlayer.heightAnchor.constraint(equalToConstant: 61),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    miniPlayer.bind(player: player)
    player.play()
  }

  override func videoPlayer(
    _ player: FKVideoPlayer,
    didChangeState state: FKMediaPlaybackState
  ) {
    super.videoPlayer(player, didChangeState: state)
    miniPlayer.handleStateChange(state)
  }

  override func videoPlayer(
    _ player: FKVideoPlayer,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  ) {
    super.videoPlayer(player, didUpdateTime: current, duration: duration)
    miniPlayer.updateProgress()
  }
}
