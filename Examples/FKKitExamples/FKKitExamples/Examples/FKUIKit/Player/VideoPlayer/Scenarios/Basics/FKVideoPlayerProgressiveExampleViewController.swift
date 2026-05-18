import FKUIKit
import UIKit

/// Plays a progressive MP4 over HTTPS with default chrome.
@MainActor
final class FKVideoPlayerProgressiveExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Progressive MP4"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Demonstrates `load`, `bind`, and transport controls. Uses Blender Big Buck Bunny (~10 min) with a W3C Sintel trailer fallback. Requires network access."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    player.play()
  }
}
