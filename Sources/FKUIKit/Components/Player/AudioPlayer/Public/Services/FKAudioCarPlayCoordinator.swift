import MediaPlayer
import UIKit

/// CarPlay / lock-screen command helpers. Template metadata APIs are not implemented yet.
@MainActor
public final class FKAudioCarPlayCoordinator {

  public weak var player: FKAudioPlayer?

  public init(player: FKAudioPlayer? = nil) {
    self.player = player
  }

  /// Publishes queue-aware Now Playing commands for CarPlay and lock screen.
  public func activate() {
    player?.refreshRemoteTrackCommands()
  }

  public func deactivate() {
    player?.unregisterRemoteTrackCommands()
  }

  /// Ensures Now Playing metadata is enabled. CarPlay template artwork is not pushed here yet.
  public func refreshMetadata() {
    guard let player, player.currentItem != nil else { return }
    player.coordinator.configuration.enablesNowPlayingInfo = true
  }
}
