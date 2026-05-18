import Foundation

/// Phase 3 playback options (LL-HLS, FairPlay flags).
public struct FKMediaAdvancedPlaybackOptions: Sendable, Equatable {
  public var enablesLowLatencyHLS: Bool
  public var preferredLiveOffsetSeconds: TimeInterval
  public var enablesFairPlay: Bool

  public init(
    enablesLowLatencyHLS: Bool = false,
    preferredLiveOffsetSeconds: TimeInterval = 3,
    enablesFairPlay: Bool = false
  ) {
    self.enablesLowLatencyHLS = enablesLowLatencyHLS
    self.preferredLiveOffsetSeconds = preferredLiveOffsetSeconds
    self.enablesFairPlay = enablesFairPlay
  }

  public static let `default` = FKMediaAdvancedPlaybackOptions()
}
