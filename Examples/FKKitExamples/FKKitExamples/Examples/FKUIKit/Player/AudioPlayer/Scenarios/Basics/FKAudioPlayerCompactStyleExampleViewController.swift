import FKUIKit
import UIKit

/// Uses ``FKAudioPlayerViewStyle/compact`` for a denser control surface.
@MainActor
final class FKAudioPlayerCompactStyleExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Compact style"
    playerViewStyle = .compact
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Same APIs as the standard layout with reduced vertical chrome."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    playerHeightMultiplier = 0.28
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackTwo(), autoPlay: true)
  }
}
