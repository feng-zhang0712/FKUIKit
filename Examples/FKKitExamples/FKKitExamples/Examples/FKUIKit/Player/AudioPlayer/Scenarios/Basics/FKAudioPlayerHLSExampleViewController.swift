import FKUIKit
import UIKit

/// Plays an HLS VOD stream in audio-only presentation mode.
@MainActor
final class FKAudioPlayerHLSExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "HLS on demand"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Uses the Apple Bip-Bop master playlist. Video tracks are ignored in `.audioOnly` mode."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.hlsItem(), autoPlay: true)
  }
}
