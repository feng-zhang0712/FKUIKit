import Foundation

/// A single audio track consumed by ``FKAudioPlayer``.
public struct FKAudioItem: Sendable, Identifiable, Equatable {
  public let id: String
  public let source: FKMediaSource
  public var title: String?
  public var artist: String?
  public var albumTitle: String?
  public var artworkURL: URL?
  public var lyricsURL: URL?
  public var lyricsText: String?
  public var chapters: [FKAudioChapter]
  public var startPosition: TimeInterval?

  public init(
    id: String = UUID().uuidString,
    source: FKMediaSource,
    title: String? = nil,
    artist: String? = nil,
    albumTitle: String? = nil,
    artworkURL: URL? = nil,
    lyricsURL: URL? = nil,
    lyricsText: String? = nil,
    chapters: [FKAudioChapter] = [],
    startPosition: TimeInterval? = nil
  ) {
    self.id = id
    self.source = source
    self.title = title
    self.artist = artist
    self.albumTitle = albumTitle
    self.artworkURL = artworkURL
    self.lyricsURL = lyricsURL
    self.lyricsText = lyricsText
    self.chapters = chapters
    self.startPosition = startPosition
  }

  public func toMediaItem() -> FKMediaItem {
    FKMediaItem(
      id: id,
      source: source,
      title: title,
      artist: artist,
      artworkURL: artworkURL,
      albumTitle: albumTitle,
      startPosition: startPosition
    )
  }
}

extension FKAudioItem {

  public static func == (lhs: FKAudioItem, rhs: FKAudioItem) -> Bool {
    lhs.id == rhs.id
      && lhs.source == rhs.source
      && lhs.title == rhs.title
      && lhs.artist == rhs.artist
      && lhs.albumTitle == rhs.albumTitle
      && lhs.artworkURL == rhs.artworkURL
      && lhs.lyricsURL == rhs.lyricsURL
      && lhs.lyricsText == rhs.lyricsText
      && lhs.chapters == rhs.chapters
      && lhs.startPosition == rhs.startPosition
  }
}
