import FKUIKit
import UIKit

/// External WebVTT plus embedded legible track listing.
@MainActor
final class FKVideoPlayerSubtitlesExampleViewController: FKVideoPlayerExampleShellViewController {

  private let tracksLabel = UILabel()

  override func viewDidLoad() {
    title = "Subtitles"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Loads bundled `sample-en.vtt`. Embedded track names appear after the asset is ready."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    tracksLabel.font = .preferredFont(forTextStyle: .footnote)
    tracksLabel.textColor = .secondaryLabel
    tracksLabel.numberOfLines = 0

    let pickFirst = FKVideoPlayerExampleLayout.makePrimaryButton("Select first embedded subtitle", action: UIAction { [weak self] _ in
      guard let name = self?.player.embeddedSubtitleTrackNames.first else { return }
      self?.player.selectEmbeddedSubtitle(named: name)
    })

    let stack = UIStackView(arrangedSubviews: [tracksLabel, pickFirst])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    let item = FKVideoPlayerExampleCatalog.itemWithExternalSubtitles()
    if FKVideoPlayerExampleCatalog.bundledWebVTTURL() == nil {
      tracksLabel.text = "Bundled VTT missing from app resources."
    }
    player.load(item)
    player.play()
  }

  override func videoPlayer(_ player: FKVideoPlayer, didChangeState state: FKMediaPlaybackState) {
    super.videoPlayer(player, didChangeState: state)
    if case .ready = state, !player.embeddedSubtitleTrackNames.isEmpty {
      tracksLabel.text = "Embedded: " + player.embeddedSubtitleTrackNames.joined(separator: ", ")
    }
  }
}
