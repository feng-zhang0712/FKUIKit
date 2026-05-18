import Foundation

/// Ordered list of videos for sequential playback.
public struct FKVideoPlaylist: Sendable, Equatable, Identifiable {
  public let id: String
  public var items: [FKVideoItem]
  public var currentIndex: Int

  public init(
    id: String = UUID().uuidString,
    items: [FKVideoItem],
    currentIndex: Int = 0
  ) {
    self.id = id
    self.items = items
    self.currentIndex = min(max(0, currentIndex), max(0, items.count - 1))
  }

  /// Maps into ``FKMediaPlaylist`` for ``FKMediaPlaybackCoordinator``.
  public func toMediaPlaylist() -> FKMediaPlaylist {
    FKMediaPlaylist(
      id: id,
      items: items.map { $0.toMediaItem() },
      startIndex: currentIndex
    )
  }

  public var currentItem: FKVideoItem? {
    guard items.indices.contains(currentIndex) else { return nil }
    return items[currentIndex]
  }

  public mutating func advance() -> FKVideoItem? {
    guard currentIndex + 1 < items.count else { return nil }
    currentIndex += 1
    return currentItem
  }

  public mutating func retreat() -> FKVideoItem? {
    guard currentIndex > 0 else { return nil }
    currentIndex -= 1
    return currentItem
  }
}
