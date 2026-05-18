import FKUIKit
import SwiftUI
import UIKit

/// Hosts ``FKVideoPlayerSwiftUIView`` inside a UIHostingController.
@MainActor
final class FKVideoPlayerSwiftUIExampleViewController: UIViewController {

  private let player = FKVideoPlayer()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridge"
    view.backgroundColor = .systemGroupedBackground

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "SwiftUI representable wrapping the same `FKVideoPlayer` instance."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let hosting = UIHostingController(
      rootView: FKVideoPlayerSwiftUIView(player: player)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    )
    addChild(hosting)
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    hosting.view.layer.cornerRadius = 12
    hosting.view.clipsToBounds = true
    view.addSubview(hosting.view)
    hosting.didMove(toParent: self)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      hosting.view.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
      hosting.view.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      hosting.view.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.5),
    ])

    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    player.play()
  }
}
