import Foundation

/// A single timed lyric line parsed from LRC.
public struct FKAudioLyricLine: Sendable, Equatable {
  public let time: TimeInterval
  public let text: String
}
