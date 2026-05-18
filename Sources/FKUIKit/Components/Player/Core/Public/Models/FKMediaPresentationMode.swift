import Foundation

/// Controls whether video rendering is required for the current session.
public enum FKMediaPresentationMode: Sendable, Equatable {
  /// Attach and display video via `AVPlayerLayer` when available.
  case video
  /// Audio-only playback; no video layer attachment.
  case audioOnly
}
