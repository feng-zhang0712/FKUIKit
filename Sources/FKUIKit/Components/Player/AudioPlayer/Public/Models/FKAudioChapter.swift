import Foundation

/// A chapter marker for podcasts or long-form audio.
public struct FKAudioChapter: Sendable, Hashable, Identifiable {
  public let id: String
  public var title: String
  public var time: TimeInterval

  public init(
    id: String = UUID().uuidString,
    title: String,
    time: TimeInterval
  ) {
    self.id = id
    self.title = title
    self.time = time
  }
}
