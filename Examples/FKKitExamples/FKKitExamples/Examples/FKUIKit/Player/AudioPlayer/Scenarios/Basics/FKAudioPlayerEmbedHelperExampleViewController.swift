import FKUIKit
import UIKit

/// Embeds audio chrome via ``UIView/fk_embedAudioPlayer(_:style:)``.
@MainActor
final class FKAudioPlayerEmbedHelperExampleViewController: UIViewController {

  private let player = FKAudioPlayer()
  private let hostView = UIView()

  override func viewDidLoad() {
    title = "Embed helper"
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "The helper pins `FKAudioPlayerView` to all edges of a host container."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false

    hostView.backgroundColor = .secondarySystemGroupedBackground
    hostView.layer.cornerRadius = 12
    hostView.translatesAutoresizingMaskIntoConstraints = false
    _ = hostView.fk_embedAudioPlayer(player, style: .standard)

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

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }
}
