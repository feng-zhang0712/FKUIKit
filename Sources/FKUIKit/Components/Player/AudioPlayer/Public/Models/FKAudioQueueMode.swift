import Foundation

/// How ``FKAudioQueue`` advances between tracks.
public enum FKAudioQueueMode: String, Sendable, Equatable {
  case sequential
  case shuffle
  case repeatOne
  case repeatAll
}
