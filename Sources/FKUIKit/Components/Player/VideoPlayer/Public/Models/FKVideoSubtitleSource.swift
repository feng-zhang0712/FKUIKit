import Foundation

/// External subtitle resource attached to a video item.
public enum FKVideoSubtitleSource: Sendable, Equatable {
  case bundled(url: URL, format: FKVideoSubtitleFormat)
  case remote(url: URL, format: FKVideoSubtitleFormat)
}
