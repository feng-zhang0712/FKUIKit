import FKUIKit
import UIKit

/// Loads bundled LRC lyrics into ``FKAudioLyricsView``.
@MainActor
final class FKAudioPlayerLRCLyricsExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Bundled LRC"
    usesExternalLyricsPanel = true
    playerHeightMultiplier = 0.36
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Loads bundled `sample.lrc`. Lyrics appear in the panel below the player while audio plays."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.itemWithBundledLRC(), autoPlay: true)
  }
}
