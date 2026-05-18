import Foundation

/// A single playable media entry consumed by ``FKMediaPlaybackCoordinator``.
public struct FKMediaItem: Sendable, Identifiable, Equatable {
  public let id: String
  public let source: FKMediaSource
  public var title: String?
  public var artist: String?
  public var artworkURL: URL?
  public var albumTitle: String?
  public var startPosition: TimeInterval?
  public var metadata: [String: String]

  public init(
    id: String,
    source: FKMediaSource,
    title: String? = nil,
    artist: String? = nil,
    artworkURL: URL? = nil,
    albumTitle: String? = nil,
    startPosition: TimeInterval? = nil,
    metadata: [String: String] = [:]
  ) {
    self.id = id
    self.source = source
    self.title = title
    self.artist = artist
    self.artworkURL = artworkURL
    self.albumTitle = albumTitle
    self.startPosition = startPosition
    self.metadata = metadata
  }
}

extension FKMediaItem {

  public static func == (lhs: FKMediaItem, rhs: FKMediaItem) -> Bool {
    lhs.id == rhs.id
      && lhs.source == rhs.source
      && lhs.title == rhs.title
      && lhs.artist == rhs.artist
      && lhs.artworkURL == rhs.artworkURL
      && lhs.albumTitle == rhs.albumTitle
      && lhs.startPosition == rhs.startPosition
      && lhs.metadata == rhs.metadata
  }
}
