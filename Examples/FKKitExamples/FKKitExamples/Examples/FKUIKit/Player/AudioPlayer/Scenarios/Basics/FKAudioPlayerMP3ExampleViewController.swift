import FKUIKit
import UIKit

/// Plays a progressive MP3 over HTTPS with default audio chrome.
@MainActor
final class FKAudioPlayerMP3ExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Progressive MP3"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Demonstrates `load`, `bind`, transport controls, and artwork. Requires network access."
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
