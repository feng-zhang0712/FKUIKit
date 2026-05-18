import FKUIKit
import UIKit

/// Runs the built-in ad plugin placeholder before playback.
@MainActor
final class FKVideoPlayerAdsExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Pre-roll ads"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Assigns `FKVideoAdCoordinator` and calls `playPrerollAd` before starting content."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let play = FKVideoPlayerExampleLayout.makePrimaryButton("Load with pre-roll", action: UIAction { [weak self] _ in
      Task { await self?.loadWithPreroll() }
    })
    addFooterControls(play)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.adPlugin = FKVideoAdCoordinator()
    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
  }

  private func loadWithPreroll() async {
    await player.playPrerollAd(from: self)
    player.play()
  }
}
