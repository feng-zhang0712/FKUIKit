import Foundation

/// High-level classification of media content.
public enum FKMediaType: String, Sendable, Equatable {
  case video
  case audio
  case multiplex
}
