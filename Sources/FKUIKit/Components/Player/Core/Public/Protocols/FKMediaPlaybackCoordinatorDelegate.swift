import Foundation

/// Receives playback lifecycle and progress updates from ``FKMediaPlaybackCoordinator``.
@MainActor
public protocol FKMediaPlaybackCoordinatorDelegate: AnyObject {
  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didChangeState state: FKMediaPlaybackState
  )

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  )

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateBuffered ranges: [ClosedRange<TimeInterval>]
  )

  func mediaPlaybackCoordinatorDidFinish(_ coordinator: FKMediaPlaybackCoordinator)

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didFail error: FKMediaError
  )

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didAdvanceTo item: FKMediaItem,
    at index: Int,
    in playlist: FKMediaPlaylist
  )
}

extension FKMediaPlaybackCoordinatorDelegate {
  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  ) {}

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateBuffered ranges: [ClosedRange<TimeInterval>]
  ) {}

  public func mediaPlaybackCoordinatorDidFinish(_ coordinator: FKMediaPlaybackCoordinator) {}

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didAdvanceTo item: FKMediaItem,
    at index: Int,
    in playlist: FKMediaPlaylist
  ) {}
}
