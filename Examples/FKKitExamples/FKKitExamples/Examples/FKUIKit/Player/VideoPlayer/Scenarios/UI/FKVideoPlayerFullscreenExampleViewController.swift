import FKUIKit
import UIKit

/// Presents ``FKVideoPlayerViewController`` for immersive playback.
@MainActor
final class FKVideoPlayerFullscreenExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Fullscreen"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Inline player below; tap Enter fullscreen to present the dedicated host view controller."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let fullscreen = FKVideoPlayerExampleLayout.makePrimaryButton("Enter fullscreen", action: UIAction { [weak self] _ in
      guard let self else { return }
      let host = FKVideoPlayerViewController(player: self.player, embeddedView: self.playerView)
      self.present(host, animated: true)
    })
    addFooterControls(fullscreen)

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
