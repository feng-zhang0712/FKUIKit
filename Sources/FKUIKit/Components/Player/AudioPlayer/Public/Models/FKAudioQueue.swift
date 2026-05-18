import Foundation

/// Manages the ordered list of tracks and shuffle state for ``FKAudioPlayer``.
@MainActor
public final class FKAudioQueue {

  public var mode: FKAudioQueueMode {
    didSet { rebuildShuffleOrderIfNeeded() }
  }

  public private(set) var items: [FKAudioItem] = []
  public private(set) var currentIndex: Int?

  private var shuffleOrder: [Int] = []
  private var shuffleCursor: Int = 0

  public init(mode: FKAudioQueueMode = .sequential) {
    self.mode = mode
  }

  public func replace(_ items: [FKAudioItem], startIndex: Int = 0) {
    self.items = items
    let index = min(max(0, startIndex), max(0, items.count - 1))
    currentIndex = items.isEmpty ? nil : index
    rebuildShuffleOrderIfNeeded()
    if mode == .shuffle, let currentIndex {
      shuffleCursor = shuffleOrder.firstIndex(of: currentIndex) ?? 0
    }
  }

  public func insertNext(_ item: FKAudioItem) {
    guard let index = currentIndex else {
      append(item)
      return
    }
    let insertAt = min(index + 1, items.count)
    items.insert(item, at: insertAt)
    rebuildShuffleOrderIfNeeded()
  }

  public func append(_ item: FKAudioItem) {
    items.append(item)
    if currentIndex == nil {
      currentIndex = items.count - 1
    }
    rebuildShuffleOrderIfNeeded()
  }

  public func remove(at index: Int) {
    guard items.indices.contains(index) else { return }
    items.remove(at: index)
    if items.isEmpty {
      currentIndex = nil
    } else if let current = currentIndex {
      if index < current {
        currentIndex = current - 1
      } else if index == current {
        currentIndex = min(current, items.count - 1)
      }
    }
    rebuildShuffleOrderIfNeeded()
  }

  public func clear() {
    items = []
    currentIndex = nil
    shuffleOrder = []
    shuffleCursor = 0
  }

  public var currentItem: FKAudioItem? {
    guard let currentIndex, items.indices.contains(currentIndex) else { return nil }
    return items[currentIndex]
  }

  public func setCurrentIndex(_ index: Int) {
    guard items.indices.contains(index) else { return }
    currentIndex = index
    if mode == .shuffle, let position = shuffleOrder.firstIndex(of: index) {
      shuffleCursor = position
    }
  }

  /// Advances according to ``mode`` and returns the next item to play.
  public func advance() -> FKAudioItem? {
    guard !items.isEmpty else { return nil }

    switch mode {
    case .repeatOne:
      return currentItem

    case .repeatAll:
      guard let current = currentIndex else {
        currentIndex = 0
        return items.first
      }
      let next = (current + 1) % items.count
      currentIndex = next
      return items[next]

    case .sequential:
      guard let current = currentIndex else {
        currentIndex = 0
        return items.first
      }
      let next = current + 1
      guard items.indices.contains(next) else { return nil }
      currentIndex = next
      return items[next]

    case .shuffle:
      guard !shuffleOrder.isEmpty else { return nil }
      if currentIndex == nil {
        shuffleCursor = 0
        currentIndex = shuffleOrder[0]
        return currentItem
      }
      shuffleCursor = (shuffleCursor + 1) % shuffleOrder.count
      currentIndex = shuffleOrder[shuffleCursor]
      return currentItem
    }
  }

  /// Moves to the previous item according to ``mode``.
  public func retreat() -> FKAudioItem? {
    guard !items.isEmpty else { return nil }

    switch mode {
    case .repeatOne:
      return currentItem

    case .repeatAll, .sequential:
      guard let current = currentIndex else {
        currentIndex = 0
        return items.first
      }
      let previous = current - 1
      guard items.indices.contains(previous) else { return nil }
      currentIndex = previous
      return items[previous]

    case .shuffle:
      guard !shuffleOrder.isEmpty else { return nil }
      if currentIndex == nil {
        shuffleCursor = 0
        currentIndex = shuffleOrder[0]
        return currentItem
      }
      shuffleCursor = (shuffleCursor - 1 + shuffleOrder.count) % shuffleOrder.count
      currentIndex = shuffleOrder[shuffleCursor]
      return currentItem
    }
  }

  public func toMediaPlaylist(id: String = "FKAudioQueue") -> FKMediaPlaylist {
    FKMediaPlaylist(
      id: id,
      items: items.map { $0.toMediaItem() },
      startIndex: currentIndex ?? 0
    )
  }

  // MARK: - Private

  private func rebuildShuffleOrderIfNeeded() {
    guard mode == .shuffle else {
      shuffleOrder = []
      shuffleCursor = 0
      return
    }
    shuffleOrder = Array(items.indices).shuffled()
    if let currentIndex, let position = shuffleOrder.firstIndex(of: currentIndex) {
      shuffleCursor = position
    } else {
      shuffleCursor = 0
      self.currentIndex = shuffleOrder.first
    }
  }
}
