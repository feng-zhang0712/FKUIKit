import Foundation

/// Receives playback and queue updates from ``FKAudioPlayer``.
@MainActor
public protocol FKAudioPlayerDelegate: AnyObject {
  func audioPlayer(_ player: FKAudioPlayer, didChangeState state: FKMediaPlaybackState)
  func audioPlayer(_ player: FKAudioPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval)
  func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?)
  func audioPlayerDidFinish(_ player: FKAudioPlayer)
  func audioPlayer(_ player: FKAudioPlayer, didFail error: FKMediaError)
  func audioPlayer(_ player: FKAudioPlayer, didUpdateLyricsLine index: Int?)
  func audioPlayer(_ player: FKAudioPlayer, didLoadLyrics lines: [FKAudioLyricLine])
  func audioPlayer(_ player: FKAudioPlayer, didChangeQueueIndex index: Int?)
}

extension FKAudioPlayerDelegate {
  public func audioPlayer(_ player: FKAudioPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {}
  public func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {}
  public func audioPlayerDidFinish(_ player: FKAudioPlayer) {}
  public func audioPlayer(_ player: FKAudioPlayer, didUpdateLyricsLine index: Int?) {}
  public func audioPlayer(_ player: FKAudioPlayer, didLoadLyrics lines: [FKAudioLyricLine]) {}
  public func audioPlayer(_ player: FKAudioPlayer, didChangeQueueIndex index: Int?) {}
}
