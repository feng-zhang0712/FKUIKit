import UIKit

/// In-memory cache for expensive collapsed `NSAttributedString` builds.
@MainActor
final class FKExpandableTextLayoutCache {
  static let shared = FKExpandableTextLayoutCache()

  private final class WrappedValue {
    let value: NSAttributedString
    init(_ value: NSAttributedString) {
      self.value = value
    }
  }

  private let cache = NSCache<NSString, WrappedValue>()

  private init() {
    cache.countLimit = 512
  }

  func value(forKey key: String) -> NSAttributedString? {
    cache.object(forKey: key as NSString)?.value
  }

  func setValue(_ value: NSAttributedString, forKey key: String) {
    cache.setObject(WrappedValue(value), forKey: key as NSString)
  }

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
