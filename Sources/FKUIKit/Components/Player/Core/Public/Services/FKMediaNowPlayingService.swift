import AVFoundation
import Foundation
import MediaPlayer
import UIKit

/// Updates Lock Screen and Control Center now-playing metadata and remote commands.
@MainActor
public final class FKMediaNowPlayingService {

  public var isEnabled = true

  private weak var commandTarget: FKMediaNowPlayingCommandTarget?
  private var commandRegistrations: [(command: MPRemoteCommand, token: Any)] = []
  private var playlistSkipRegistrations: [(command: MPRemoteCommand, token: Any)] = []

  public init() {}

  /// Publishes metadata for the current item.
  public func updateNowPlaying(
    item: FKMediaItem?,
    currentTime: TimeInterval,
    duration: TimeInterval,
    rate: Float,
    isPlaying: Bool
  ) {
    guard isEnabled else { return }

    var info = [String: Any]()
    info[MPMediaItemPropertyTitle] = item?.title ?? ""
    info[MPMediaItemPropertyArtist] = item?.artist ?? ""
    info[MPMediaItemPropertyAlbumTitle] = item?.albumTitle ?? ""
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    info[MPMediaItemPropertyPlaybackDuration] = duration.isFinite ? duration : 0
    info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? rate : 0
    if let itemID = item?.id {
      info[MPNowPlayingInfoPropertyExternalContentIdentifier] = itemID
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = info

    if let artworkURL = item?.artworkURL, let itemID = item?.id {
      Task {
        guard let image = await Self.loadImage(from: artworkURL) else { return }
        await MainActor.run {
          let currentID = MPNowPlayingInfoCenter.default().nowPlayingInfo?[
            MPNowPlayingInfoPropertyExternalContentIdentifier
          ] as? String
          guard currentID == itemID else { return }
          let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
          var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? info
          updated[MPMediaItemPropertyArtwork] = artwork
          MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
        }
      }
    }
  }

  /// Registers play/pause/seek (and optional skip) remote commands for ``target`` only.
  public func registerCommands(target: FKMediaNowPlayingCommandTarget) {
    commandTarget = target
    unregisterCommands()

    let center = MPRemoteCommandCenter.shared()

    center.playCommand.isEnabled = true
    center.pauseCommand.isEnabled = true
    center.togglePlayPauseCommand.isEnabled = true
    center.changePlaybackPositionCommand.isEnabled = true
    commandRegistrations = [
      (center.playCommand, center.playCommand.addTarget { [weak target] _ in
        target?.remotePlay() ?? .commandFailed
      }),
      (center.pauseCommand, center.pauseCommand.addTarget { [weak target] _ in
        target?.remotePause() ?? .commandFailed
      }),
      (center.togglePlayPauseCommand, center.togglePlayPauseCommand.addTarget { [weak target] _ in
        target?.remoteTogglePlayPause() ?? .commandFailed
      }),
      (center.changePlaybackPositionCommand, center.changePlaybackPositionCommand.addTarget { [weak target] event in
        guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
          return .commandFailed
        }
        return target?.remoteSeek(to: positionEvent.positionTime) ?? .commandFailed
      }),
    ]
  }

  private func unregisterCommands() {
    for registration in commandRegistrations {
      registration.command.removeTarget(registration.token)
    }
    commandRegistrations.removeAll()
  }

  /// Registers next/previous track commands for coordinator playlist navigation.
  public func registerPlaylistSkipCommands(target: FKMediaNowPlayingCommandTarget) {
    unregisterPlaylistSkipCommands()
    let center = MPRemoteCommandCenter.shared()
    center.nextTrackCommand.isEnabled = true
    center.previousTrackCommand.isEnabled = true
    playlistSkipRegistrations = [
      (center.nextTrackCommand, center.nextTrackCommand.addTarget { [weak target] _ in
        target?.remoteNextTrack() ?? .commandFailed
      }),
      (center.previousTrackCommand, center.previousTrackCommand.addTarget { [weak target] _ in
        target?.remotePreviousTrack() ?? .commandFailed
      }),
    ]
  }

  public func unregisterPlaylistSkipCommands() {
    for registration in playlistSkipRegistrations {
      registration.command.removeTarget(registration.token)
    }
    playlistSkipRegistrations.removeAll()
  }

  public func clear() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }

  private static func loadImage(from url: URL) async -> UIImage? {
    if url.isFileURL {
      return UIImage(contentsOfFile: url.path)
    }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      return UIImage(data: data)
    } catch {
      return nil
    }
  }
}

/// Handles remote command callbacks from ``FKMediaNowPlayingService``.
@MainActor
public protocol FKMediaNowPlayingCommandTarget: AnyObject {
  func remotePlay() -> MPRemoteCommandHandlerStatus
  func remotePause() -> MPRemoteCommandHandlerStatus
  func remoteTogglePlayPause() -> MPRemoteCommandHandlerStatus
  func remoteSeek(to time: TimeInterval) -> MPRemoteCommandHandlerStatus
  func remoteNextTrack() -> MPRemoteCommandHandlerStatus
  func remotePreviousTrack() -> MPRemoteCommandHandlerStatus
}

extension FKMediaNowPlayingCommandTarget {
  public func remoteNextTrack() -> MPRemoteCommandHandlerStatus { .commandFailed }
  public func remotePreviousTrack() -> MPRemoteCommandHandlerStatus { .commandFailed }
}
