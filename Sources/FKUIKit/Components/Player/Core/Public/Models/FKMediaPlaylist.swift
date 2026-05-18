import Foundation

/// Ordered collection of items played sequentially by ``FKMediaPlaybackCoordinator``.
public struct FKMediaPlaylist: Sendable, Equatable, Identifiable {
  public let id: String
  public var items: [FKMediaItem]
  public var startIndex: Int

  public init(
    id: String,
    items: [FKMediaItem],
    startIndex: Int = 0
  ) {
    self.id = id
    self.items = items
    self.startIndex = min(max(0, startIndex), max(0, items.count - 1))
  }

  public var isEmpty: Bool { items.isEmpty }
}
