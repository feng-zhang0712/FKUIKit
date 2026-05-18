import Foundation

/// A video item consumed by ``FKVideoPlayer``.
public struct FKVideoItem: Sendable, Identifiable, Equatable {
  public let id: String
  public let source: FKMediaSource
  public var title: String?
  public var artworkURL: URL?
  public var posterURL: URL?
  public var chapters: [FKVideoChapter]
  public var skipIntroDuration: TimeInterval?
  public var skipOutroDuration: TimeInterval?
  public var subtitleSources: [FKVideoSubtitleSource]
  public var startPosition: TimeInterval?

  public init(
    id: String = UUID().uuidString,
    source: FKMediaSource,
    title: String? = nil,
    artworkURL: URL? = nil,
    posterURL: URL? = nil,
    chapters: [FKVideoChapter] = [],
    skipIntroDuration: TimeInterval? = nil,
    skipOutroDuration: TimeInterval? = nil,
    subtitleSources: [FKVideoSubtitleSource] = [],
    startPosition: TimeInterval? = nil
  ) {
    self.id = id
    self.source = source
    self.title = title
    self.artworkURL = artworkURL
    self.posterURL = posterURL
    self.chapters = chapters
    self.skipIntroDuration = skipIntroDuration
    self.skipOutroDuration = skipOutroDuration
    self.subtitleSources = subtitleSources
    self.startPosition = startPosition
  }

  /// Maps into the shared media model used by ``FKMediaPlaybackCoordinator``.
  public func toMediaItem() -> FKMediaItem {
    FKMediaItem(
      id: id,
      source: source,
      title: title,
      artist: nil,
      artworkURL: artworkURL ?? posterURL,
      albumTitle: nil,
      startPosition: startPosition
    )
  }
}

extension FKVideoItem {

  public static func == (lhs: FKVideoItem, rhs: FKVideoItem) -> Bool {
    lhs.id == rhs.id
      && lhs.source == rhs.source
      && lhs.title == rhs.title
      && lhs.artworkURL == rhs.artworkURL
      && lhs.posterURL == rhs.posterURL
      && lhs.chapters == rhs.chapters
      && lhs.skipIntroDuration == rhs.skipIntroDuration
      && lhs.skipOutroDuration == rhs.skipOutroDuration
      && lhs.subtitleSources == rhs.subtitleSources
      && lhs.startPosition == rhs.startPosition
  }
}
