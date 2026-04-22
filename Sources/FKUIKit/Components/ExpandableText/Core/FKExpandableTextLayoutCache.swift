import UIKit

/// Caches collapsed text layouts to avoid rebuilding the same attributed output repeatedly.
@MainActor
final class FKExpandableTextLayoutCache {
  /// Shared cache instance used by all expandable text renderers on the main actor.
  static let shared = FKExpandableTextLayoutCache()

  /// Wraps attributed text so it can be stored in `NSCache`.
  private final class WrappedValue {
    let value: NSAttributedString
    init(_ value: NSAttributedString) {
      self.value = value
    }
  }

  /// Uses `NSCache` for automatic eviction under memory pressure.
  private let cache = NSCache<NSString, WrappedValue>()

  private init() {
    cache.countLimit = 512
  }

  /// Returns a cached collapsed representation for the provided cache key.
  func value(forKey key: String) -> NSAttributedString? {
    cache.object(forKey: key as NSString)?.value
  }

  /// Stores a collapsed representation for later reuse.
  func setValue(_ value: NSAttributedString, forKey key: String) {
    cache.setObject(WrappedValue(value), forKey: key as NSString)
  }

  /// Builds a stable-enough cache key from layout-affecting inputs.
  func makeKey(
    text: NSAttributedString,
    width: CGFloat,
    numberOfLines: Int,
    lineBreakMode: NSLineBreakMode,
    placement: FKExpandableTextConfiguration.ButtonPlacement,
    actionText: NSAttributedString,
    token: NSAttributedString
  ) -> String {
    [
      "\(text.string.hashValue)",
      "\(text.length)",
      "\(width.rounded(.toNearestOrAwayFromZero))",
      "\(numberOfLines)",
      "\(lineBreakMode.rawValue)",
      "\(placement == .inlineTail ? 0 : 1)",
      "\(actionText.string.hashValue)",
      "\(token.string.hashValue)",
    ].joined(separator: "|")
  }
}
