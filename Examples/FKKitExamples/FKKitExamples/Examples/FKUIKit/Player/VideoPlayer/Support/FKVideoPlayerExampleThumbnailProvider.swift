import FKUIKit
import UIKit

/// Generates preview images for scrubbing demos using ``FKVideoPlayer/captureThumbnail(at:)``.
@MainActor
final class FKVideoPlayerExampleThumbnailProvider: FKVideoThumbnailProvider {

  private weak var player: FKVideoPlayer?

  init(player: FKVideoPlayer) {
    self.player = player
  }

  func thumbnail(at time: TimeInterval) async -> UIImage? {
    await player?.captureThumbnail(at: time)
  }
}
