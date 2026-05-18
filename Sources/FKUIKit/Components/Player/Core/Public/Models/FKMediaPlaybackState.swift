import Foundation

/// Lifecycle state of a playback session.
public enum FKMediaPlaybackState: Sendable, Equatable {
  case idle
  case preparing
  case ready
  case playing
  case paused
  case buffering
  case completed
  case failed(FKMediaError)
}

extension FKMediaPlaybackState {

  /// Whether playback is actively progressing (playing or buffering).
  public var isActive: Bool {
    switch self {
    case .playing, .buffering:
      return true
    case .idle, .preparing, .ready, .paused, .completed, .failed:
      return false
    }
  }

  /// Whether the session has ended unsuccessfully.
  public var isFailed: Bool {
    if case .failed = self { return true }
    return false
  }
}
