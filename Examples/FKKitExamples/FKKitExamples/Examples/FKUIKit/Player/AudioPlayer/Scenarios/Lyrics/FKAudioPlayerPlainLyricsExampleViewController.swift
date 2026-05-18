import FKUIKit
import UIKit

/// Inline plain-text lyrics with optional timestamp lines.
@MainActor
final class FKAudioPlayerPlainLyricsExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Plain lyrics"
    usesExternalLyricsPanel = true
    playerHeightMultiplier = 0.36
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Sets `lyricsText` on the item. Parsed lines appear in the panel below the player."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.itemWithPlainLyrics(), autoPlay: true)
  }
}
