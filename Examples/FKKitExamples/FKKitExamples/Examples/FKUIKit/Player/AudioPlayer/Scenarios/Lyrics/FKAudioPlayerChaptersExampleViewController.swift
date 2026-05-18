import FKUIKit
import UIKit

/// Seeks to podcast chapter markers.
@MainActor
final class FKAudioPlayerChaptersExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Podcast chapters"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Chapter buttons call `seekToChapter`. Markers are defined on the `FKAudioItem`."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let item = FKAudioPlayerExampleCatalog.podcastItem()
    let buttons = item.chapters.map { chapter in
      FKAudioPlayerExampleLayout.makeSecondaryButton(chapter.title, action: UIAction { [weak self] _ in
        self?.player.seekToChapter(chapter)
      })
    }
    let stack = UIStackView(arrangedSubviews: buttons)
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(item, autoPlay: true)
  }
}
