import FKUIKit
import UIKit

/// Demonstrates ``FKAudioMiniBar`` docked above the safe area.
@MainActor
final class FKAudioPlayerMiniBarExampleViewController: FKAudioPlayerExampleShellViewController {

  private let miniBar = FKAudioMiniBar()

  override func viewDidLoad() {
    title = "Mini bar"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Standard player chrome above; tap the pill mini bar (outside the play button) to open Now Playing."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    miniBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(miniBar)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      miniBar.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 12),
      miniBar.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -12),
      miniBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.bind(miniBar: miniBar)
    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }

}
