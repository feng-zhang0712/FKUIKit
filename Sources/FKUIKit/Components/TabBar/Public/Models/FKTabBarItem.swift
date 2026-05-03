import UIKit

/// One tab in `FKTabBar`.
///
/// Keep `id` stable across reloads so selection policies (`preserveSelection`, badge updates, etc.) stay predictable.
public struct FKTabBarItem: Equatable {
  /// Stable identifier for diffing and selection retention.
  public let id: String

  /// Primary title. Style falls back to `FKTabBarConfiguration.appearance` when unspecified at item level.
  public var title: FKTabBarTextConfiguration
  public var subtitle: FKTabBarTextConfiguration?
  public var image: FKTabBarImageConfiguration?
  /// When non-`nil`, content is supplied by `FKTabBar.itemViewProvider`.
  public var customContentIdentifier: String?

  public var isEnabled: Bool
  /// Hidden items are omitted from the visible strip (`FKTabBar.visibleItems`).
  public var isHidden: Bool

  public var badge: FKTabBarBadgeConfiguration

  public var accessibilityLabel: String?
  public var accessibilityHint: String?

  public init(
    id: String,
    title: FKTabBarTextConfiguration = .init(),
    subtitle: FKTabBarTextConfiguration? = nil,
    image: FKTabBarImageConfiguration? = nil,
    customContentIdentifier: String? = nil,
    isEnabled: Bool = true,
    isHidden: Bool = false,
    badge: FKTabBarBadgeConfiguration = .init(),
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.customContentIdentifier = customContentIdentifier
    self.isEnabled = isEnabled
    self.isHidden = isHidden
    self.badge = badge
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
  }
}

public extension FKTabBarItem {
  var titleText: String? { title.normal.text }
  var subtitleText: String? { subtitle?.normal.text }
}
