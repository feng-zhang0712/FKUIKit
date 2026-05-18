import Foundation

/// Audio-specific playback preferences layered on top of Core configuration.
public struct FKAudioPlaybackPreferences: Sendable, Equatable {
  public var maxRate: Float
  public var remembersRatePerItem: Bool
  public var fadeBetweenTracksDuration: TimeInterval?
  public var enablesBackgroundPlayback: Bool

  public init(
    maxRate: Float = 2.0,
    remembersRatePerItem: Bool = true,
    fadeBetweenTracksDuration: TimeInterval? = nil,
    enablesBackgroundPlayback: Bool = true
  ) {
    self.maxRate = maxRate
    self.remembersRatePerItem = remembersRatePerItem
    self.fadeBetweenTracksDuration = fadeBetweenTracksDuration
    self.enablesBackgroundPlayback = enablesBackgroundPlayback
  }

  public static let `default` = FKAudioPlaybackPreferences()
}
