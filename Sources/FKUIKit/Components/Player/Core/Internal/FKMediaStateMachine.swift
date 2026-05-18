import Foundation

/// Validates playback state transitions.
enum FKMediaStateMachine {

  static func canTransition(from: FKMediaPlaybackState, to: FKMediaPlaybackState) -> Bool {
    if case .failed = to { return true }
    if case .failed = from { return to == .idle || to == .preparing }

    switch (from, to) {
    case (.idle, .preparing), (.idle, .idle):
      return true
    case (.preparing, .ready), (.preparing, .playing), (.preparing, .buffering), (.preparing, .failed), (.preparing, .idle):
      return true
    case (.ready, .playing), (.ready, .paused), (.ready, .buffering), (.ready, .failed), (.ready, .preparing), (.ready, .idle):
      return true
    case (.playing, .paused), (.playing, .buffering), (.playing, .completed), (.playing, .ready), (.playing, .idle), (.playing, .preparing):
      return true
    case (.paused, .playing), (.paused, .buffering), (.paused, .ready), (.paused, .idle), (.paused, .preparing):
      return true
    case (.buffering, .playing), (.buffering, .paused), (.buffering, .ready), (.buffering, .failed):
      return true
    case (.completed, .idle), (.completed, .preparing), (.completed, .playing):
      return true
    default:
      return from == to
    }
  }
}
