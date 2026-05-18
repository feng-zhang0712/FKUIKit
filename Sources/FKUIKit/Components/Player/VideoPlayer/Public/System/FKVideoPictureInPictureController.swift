import AVKit
import UIKit

/// Manages Picture in Picture for AVFoundation playback.
@MainActor
public final class FKVideoPictureInPictureController {

  private var pipController: AVPictureInPictureController?
  private weak var player: FKVideoPlayer?

  public var isPictureInPicturePossible: Bool {
    pipController?.isPictureInPicturePossible ?? false
  }

  public func configure(player: FKVideoPlayer, playerLayer: AVPlayerLayer) {
    self.player = player
    guard player.configuration.ui.allowsPictureInPicture,
          AVPictureInPictureController.isPictureInPictureSupported(),
          player.engineKind == .avFoundation else {
      pipController = nil
      return
    }
    pipController = AVPictureInPictureController(playerLayer: playerLayer)
  }

  public func startPictureInPicture() {
    pipController?.startPictureInPicture()
  }

  public func stopPictureInPicture() {
    pipController?.stopPictureInPicture()
  }
}
