import FKUIKit
import UIKit

/// Sequential playlist with skip markers and chapter jumps.
@MainActor
final class FKVideoPlayerPlaylistExampleViewController: FKVideoPlayerExampleShellViewController {

  private var pendingChapterIndex: Int?

  override func viewDidLoad() {
    title = "Playlist"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Episode 3 includes chapters. Jump switches to Episode 3, then seeks to chapter 2 (Middle)."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let previous = FKVideoPlayerExampleLayout.makePrimaryButton("Previous", action: UIAction { [weak self] _ in
      self?.player.playPreviousInPlaylist()
    })
    let next = FKVideoPlayerExampleLayout.makePrimaryButton("Next", action: UIAction { [weak self] _ in
      self?.player.playNextInPlaylist()
    })
    let chapters = FKVideoPlayerExampleLayout.makePrimaryButton("Jump to chapter 2", action: UIAction { [weak self] _ in
      self?.jumpToEpisodeThreeChapterTwo()
    })

    let row = UIStackView(arrangedSubviews: [previous, next, chapters])
    row.axis = .vertical
    row.spacing = 8
    addFooterControls(row)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(playlist: FKVideoPlayerExampleCatalog.playlist())
    player.play()
  }

  private func jumpToEpisodeThreeChapterTwo() {
    let episodeThreeIndex = 2
    let chapterIndex = 1
    guard FKVideoPlayerExampleCatalog.playlist().items[episodeThreeIndex].chapters.indices.contains(chapterIndex) else {
      return
    }

    if player.currentItem?.id == "episode.3" {
      player.seekToChapter(at: chapterIndex)
      return
    }

    pendingChapterIndex = chapterIndex
    player.playPlaylistItem(at: episodeThreeIndex)
  }

  override func videoPlayer(
    _ player: FKVideoPlayer,
    didAdvanceTo item: FKVideoItem?,
    at index: Int,
    in playlist: FKVideoPlaylist?
  ) {
    super.videoPlayer(player, didAdvanceTo: item, at: index, in: playlist)
    guard let chapterIndex = pendingChapterIndex, item?.id == "episode.3" else { return }
    pendingChapterIndex = nil
    player.seekToChapter(at: chapterIndex)
  }

  override func videoPlayer(_ player: FKVideoPlayer, didChangeState state: FKMediaPlaybackState) {
    super.videoPlayer(player, didChangeState: state)
    guard case .ready = state,
          let chapterIndex = pendingChapterIndex,
          player.currentItem?.id == "episode.3" else { return }
    pendingChapterIndex = nil
    player.seekToChapter(at: chapterIndex)
  }
}
