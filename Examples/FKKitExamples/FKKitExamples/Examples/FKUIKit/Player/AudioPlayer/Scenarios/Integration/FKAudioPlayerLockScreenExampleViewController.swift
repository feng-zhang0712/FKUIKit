import FKUIKit
import UIKit

/// Demonstrates system lock-screen / Control Center Now Playing (via Core `MPNowPlayingInfoCenter`).
@MainActor
final class FKAudioPlayerLockScreenExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Lock screen"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      """
      Start playback, then lock the device. The system Now Playing card (title, artwork, progress, transport) is published by FKMediaPlayer Core — enabled by default on `FKAudioPlayer`.

      This example target includes `UIBackgroundModes → audio` so playback continues on the lock screen.
      """
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }
}
