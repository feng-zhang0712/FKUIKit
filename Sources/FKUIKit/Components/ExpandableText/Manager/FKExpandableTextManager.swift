//
// FKExpandableTextManager.swift
//
// Shared cache manager for expandable text states and measured heights.
//

import UIKit

@MainActor
public final class FKExpandableTextManager: FKExpandableTextStateCaching {
  /// Shared singleton used by default across all expandable text instances.
  public static let shared = FKExpandableTextManager()

  /// App-wide default configuration.
  public var defaultConfiguration = FKExpandableTextConfiguration()

  /// In-memory state cache keyed by model identifier.
  private var stateCache: [String: FKExpandableTextDisplayState] = [:]
  /// In-memory height cache used for list pre-measurement.
  private let heightCache = NSCache<NSString, NSNumber>()

  /// Creates manager singleton and applies cache limits.
  private init() {
    heightCache.countLimit = 2000
  }

  /// Returns cached display state for identifier.
  ///
  /// - Parameter identifier: Stable model identifier.
  /// - Returns: Cached state or `nil` when not cached.
  public func state(for identifier: String) -> FKExpandableTextDisplayState? {
    stateCache[identifier]
  }

  /// Stores display state for a stable identifier.
  ///
  /// - Parameters:
  ///   - state: State to persist in memory.
  ///   - identifier: Stable model identifier.
  public func setState(_ state: FKExpandableTextDisplayState, for identifier: String) {
    stateCache[identifier] = state
  }

  /// Removes cached state for one identifier.
  ///
  /// - Parameter identifier: Stable model identifier.
  public func removeState(for identifier: String) {
    stateCache.removeValue(forKey: identifier)
  }

  /// Removes all cached states and measured heights.
  public func reset() {
    stateCache.removeAll()
    heightCache.removeAllObjects()
  }

  /// Returns cached height for a cache key.
  ///
  /// - Parameter cacheKey: Composite key for one text-width-state combination.
  /// - Returns: Cached height, or `nil` if not found.
  public func height(for cacheKey: String) -> CGFloat? {
    guard let value = heightCache.object(forKey: cacheKey as NSString) else {
      return nil
    }
    return CGFloat(truncating: value)
  }

  /// Caches measured height for a cache key.
  ///
  /// - Parameters:
  ///   - height: Height value to cache.
  ///   - cacheKey: Composite key for one text-width-state combination.
  public func setHeight(_ height: CGFloat, for cacheKey: String) {
    heightCache.setObject(NSNumber(value: height), forKey: cacheKey as NSString)
  }
}
