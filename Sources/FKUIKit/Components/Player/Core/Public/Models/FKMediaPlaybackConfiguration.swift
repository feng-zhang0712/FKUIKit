import Foundation

/// Playback behavior knobs (rate, loop, buffer, resume).
public struct FKMediaPlaybackConfiguration: Sendable, Equatable {
  public var autoPlay: Bool
  public var defaultRate: Float
  public var loopMode: FKMediaLoopMode
  public var resumePlaybackEnabled: Bool
  public var preferredForwardBufferDuration: TimeInterval

  public init(
    autoPlay: Bool = false,
    defaultRate: Float = 1.0,
    loopMode: FKMediaLoopMode = .none,
    resumePlaybackEnabled: Bool = true,
    preferredForwardBufferDuration: TimeInterval = 5.0
  ) {
    self.autoPlay = autoPlay
    self.defaultRate = defaultRate
    self.loopMode = loopMode
    self.resumePlaybackEnabled = resumePlaybackEnabled
    self.preferredForwardBufferDuration = preferredForwardBufferDuration
  }

  public static let `default` = FKMediaPlaybackConfiguration()
}
