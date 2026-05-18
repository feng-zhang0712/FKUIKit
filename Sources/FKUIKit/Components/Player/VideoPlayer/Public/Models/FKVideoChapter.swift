import Foundation

/// A navigable chapter marker within a video.
public struct FKVideoChapter: Sendable, Equatable, Identifiable {
  public var id: String { "\(title)-\(time)" }
  public var title: String
  public var time: TimeInterval

  public init(title: String, time: TimeInterval) {
    self.title = title
    self.time = time
  }
}
