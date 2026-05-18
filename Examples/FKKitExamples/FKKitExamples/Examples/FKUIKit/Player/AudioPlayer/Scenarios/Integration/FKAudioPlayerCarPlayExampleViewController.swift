import FKUIKit
import UIKit

/// Exercises ``FKAudioCarPlayCoordinator`` remote command registration.
@MainActor
final class FKAudioPlayerCarPlayExampleViewController: FKAudioPlayerExampleShellViewController {

  private let statusLabel = UILabel()

  override func viewDidLoad() {
    title = "CarPlay coordinator"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      """
      CarPlay builds on Core Now Playing. Remote next/previous are registered on launch. \
      “Refresh metadata” only enables Now Playing — CarPlay template artwork is not pushed yet.
      """
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Remote skip commands registered."

    let refresh = FKAudioPlayerExampleLayout.makePrimaryButton("Refresh metadata", action: UIAction { [weak self] _ in
      self?.player.carPlayCoordinator.refreshMetadata()
      self?.statusLabel.text = "Now Playing enabled for \(self?.player.currentItem?.title ?? "—")"
    })
    let deactivate = FKAudioPlayerExampleLayout.makeSecondaryButton("Deactivate remote skip", action: UIAction { [weak self] _ in
      self?.player.carPlayCoordinator.deactivate()
      self?.statusLabel.text = "Remote skip commands unregistered"
    })
    let activate = FKAudioPlayerExampleLayout.makeSecondaryButton("Activate remote skip", action: UIAction { [weak self] _ in
      self?.player.carPlayCoordinator.activate()
      self?.statusLabel.text = "Remote skip commands registered"
    })
    let stack = UIStackView(arrangedSubviews: [statusLabel, refresh, deactivate, activate])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.carPlayCoordinator.activate()
    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
  }
}
