import FKUIKit
import SwiftUI
import UIKit

/// Hosts ``FKAudioPlayerSwiftUIView`` inside a UIKit shell.
@MainActor
final class FKAudioPlayerSwiftUIExampleViewController: UIViewController {

  private let player = FKAudioPlayer()

  override func viewDidLoad() {
    title = "SwiftUI bridge"
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "SwiftUI representable binds the same `FKAudioPlayer` instance as UIKit screens."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let card = UIView()
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.clipsToBounds = true
    card.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)

    let hosting = UIHostingController(
      rootView: FKAudioPlayerSwiftUIView(player: player, style: .standard)
    )
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    hosting.view.backgroundColor = .clear
    card.addSubview(hosting.view)
    hosting.didMove(toParent: self)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      card.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      card.heightAnchor.constraint(equalToConstant: FKAudioPlayerView.standardPreferredHeight),

      hosting.view.topAnchor.constraint(equalTo: card.topAnchor),
      hosting.view.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }
}
