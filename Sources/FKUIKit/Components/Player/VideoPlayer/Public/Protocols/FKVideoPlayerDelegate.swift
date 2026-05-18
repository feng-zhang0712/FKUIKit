import Foundation

/// Receives playback events from ``FKVideoPlayer``.
@MainActor
public protocol FKVideoPlayerDelegate: AnyObject {
  func videoPlayer(_ player: FKVideoPlayer, didChangeState state: FKMediaPlaybackState)
  func videoPlayer(_ player: FKVideoPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval)
  func videoPlayer(_ player: FKVideoPlayer, didUpdateBuffered ranges: [ClosedRange<TimeInterval>])
  func videoPlayerDidFinish(_ player: FKVideoPlayer)
  func videoPlayer(_ player: FKVideoPlayer, didFail error: FKMediaError)
  func videoPlayer(_ player: FKVideoPlayer, didToggleFullscreen isFullscreen: Bool)
  func videoPlayer(
    _ player: FKVideoPlayer,
    didAdvanceTo item: FKVideoItem?,
    at index: Int,
    in playlist: FKVideoPlaylist?
  )
}

extension FKVideoPlayerDelegate {
  public func videoPlayer(_ player: FKVideoPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {}
  public func videoPlayer(_ player: FKVideoPlayer, didUpdateBuffered ranges: [ClosedRange<TimeInterval>]) {}
  public func videoPlayerDidFinish(_ player: FKVideoPlayer) {}
  public func videoPlayer(_ player: FKVideoPlayer, didToggleFullscreen isFullscreen: Bool) {}
  public func videoPlayer(
    _ player: FKVideoPlayer,
    didAdvanceTo item: FKVideoItem?,
    at index: Int,
    in playlist: FKVideoPlaylist?
  ) {}
}
