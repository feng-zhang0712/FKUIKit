import FKUIKit
import UIKit

/// Plays Apple's sample HLS VOD master playlist.
@MainActor
final class FKVideoPlayerHLSVODExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "HLS VOD"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Use the settings (⋯) control to pick playback speed or an embedded variant when available."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKVideoPlayerExampleCatalog.hlsVODItem())
    player.play()
  }
}
