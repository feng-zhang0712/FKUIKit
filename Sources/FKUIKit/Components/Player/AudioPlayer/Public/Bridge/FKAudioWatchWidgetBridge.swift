import Foundation

/// Snapshot for Watch complications / widgets (Phase 4 protocol only).
public struct FKAudioPlaybackSnapshot: Sendable, Equatable {
  public let itemID: String?
  public let title: String?
  public let artist: String?
  public let isPlaying: Bool
  public let currentTime: TimeInterval
  public let duration: TimeInterval

  public init(
    itemID: String?,
    title: String?,
    artist: String?,
    isPlaying: Bool,
    currentTime: TimeInterval,
    duration: TimeInterval
  ) {
    self.itemID = itemID
    self.title = title
    self.artist = artist
    self.isPlaying = isPlaying
    self.currentTime = currentTime
    self.duration = duration
  }
}

/// Watch extension data provider.
@MainActor
public protocol FKAudioWatchPlaybackProviding: AnyObject {
  func currentSnapshot() -> FKAudioPlaybackSnapshot
}

/// Widget timeline data provider.
@MainActor
public protocol FKAudioWidgetPlaybackProviding: AnyObject {
  func currentSnapshot() -> FKAudioPlaybackSnapshot
}

extension FKAudioPlayer: FKAudioWatchPlaybackProviding, FKAudioWidgetPlaybackProviding {

  public func currentSnapshot() -> FKAudioPlaybackSnapshot {
    FKAudioPlaybackSnapshot(
      itemID: currentItem?.id,
      title: currentItem?.title,
      artist: currentItem?.artist,
      isPlaying: state == .playing || state == .buffering,
      currentTime: currentTime,
      duration: duration
    )
  }
}
