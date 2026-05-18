import FKUIKit
import UIKit

/// Swaps default controls for ``FKVideoPlayerExampleMinimalControlView``.
@MainActor
final class FKVideoPlayerCustomControlsExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Custom controls"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Implements `FKVideoPlayerControlView` with a compact indigo overlay."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    let customControls = FKVideoPlayerExampleMinimalControlView()
    playerView.setDefaultControlView(customControls)
    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    player.play()
    playerView.revealControls(animated: false)
  }
}
