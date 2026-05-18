import Foundation

/// Root configuration for ``FKAudioPlayer``.
public struct FKAudioPlayerConfiguration: Sendable, Equatable {
  public var media: FKMediaConfiguration
  public var ui: FKAudioUIConfiguration
  public var playback: FKAudioPlaybackPreferences

  public init(
    media: FKMediaConfiguration = .default,
    ui: FKAudioUIConfiguration = .default,
    playback: FKAudioPlaybackPreferences = .default
  ) {
    self.media = media
    self.ui = ui
    self.playback = playback
  }

  public static let `default` = FKAudioPlayerConfiguration()

  public nonisolated(unsafe) static var shared: FKAudioPlayerConfiguration = .default
}
