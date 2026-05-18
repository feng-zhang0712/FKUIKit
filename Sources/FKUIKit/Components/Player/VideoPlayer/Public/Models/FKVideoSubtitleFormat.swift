import Foundation

/// External subtitle file format.
public enum FKVideoSubtitleFormat: String, Sendable, Equatable {
  case srt
  case vtt
  case ass
}
