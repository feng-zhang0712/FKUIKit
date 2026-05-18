import FKUIKit
import UIKit

/// Embeds a player using `UIView.fk_embedVideoPlayer`.
@MainActor
final class FKVideoPlayerEmbedHelperExampleViewController: UIViewController {

  private let player = FKVideoPlayer()
  private let hostView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Embed helper"
    view.backgroundColor = .systemGroupedBackground

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "The host view calls `fk_embedVideoPlayer` to install constraints and bind the layer."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false

    hostView.backgroundColor = .black
    hostView.layer.cornerRadius = 12
    hostView.clipsToBounds = true
    hostView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(caption)
    view.addSubview(hostView)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      hostView.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
      hostView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      hostView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      hostView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.45),
    ])

    _ = hostView.fk_embedVideoPlayer(player)
    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    player.play()
  }
}
