import UIKit

/// Badge payload shown on tab items.
public enum FKTabBarBadgeContent: Equatable {
  case none
  case dot
  case count(Int)
  case text(String)
  /// The actual view is provided by `FKTabBar.customBadgeViewProvider`.
  case custom(id: String)
}

/// Stateful badge content for normal/selected/disabled rendering.
public struct FKTabBarBadgeStateConfiguration: Equatable {
  public var normal: FKTabBarBadgeContent
  public var selected: FKTabBarBadgeContent?
  public var disabled: FKTabBarBadgeContent?

  public init(
    normal: FKTabBarBadgeContent = .none,
    selected: FKTabBarBadgeContent? = nil,
    disabled: FKTabBarBadgeContent? = nil
  ) {
    self.normal = normal
    self.selected = selected
    self.disabled = disabled
  }

  public func resolved(isSelected: Bool, isEnabled: Bool) -> FKTabBarBadgeContent {
    if !isEnabled {
      return disabled ?? normal
    }
    if isSelected {
      return selected ?? normal
    }
    return normal
  }
}

/// Badge placement and behavior configuration.
public struct FKTabBarBadgeConfiguration: Equatable {
  /// Stateful badge content.
  public var state: FKTabBarBadgeStateConfiguration
  /// Badge anchor relative to resolved badge target view.
  public var anchor: FKBadgeAnchor
  /// Additional x/y offset.
  ///
  /// Default intentionally shifts badge to top-right to reduce text/icon overlap.
  public var offset: UIOffset
  /// Whether the host should avoid clipping when offset is large.
  public var avoidsClipping: Bool
  /// Optional VoiceOver narration override.
  public var accessibilityValue: String?

  public init(
    state: FKTabBarBadgeStateConfiguration = .init(),
    anchor: FKBadgeAnchor = .topTrailing,
    offset: UIOffset = .init(horizontal: 6, vertical: -4),
    avoidsClipping: Bool = true,
    accessibilityValue: String? = nil
  ) {
    self.state = state
    self.anchor = anchor
    self.offset = offset
    self.avoidsClipping = avoidsClipping
    self.accessibilityValue = accessibilityValue
  }
}

public extension FKTabBarBadgeConfiguration {
  static var none: Self { .init(state: .init(normal: .none)) }
  static var dot: Self { .init(state: .init(normal: .dot)) }
  static func count(_ value: Int) -> Self { .init(state: .init(normal: .count(value))) }
  static func text(_ value: String) -> Self { .init(state: .init(normal: .text(value))) }
  static func custom(id: String) -> Self { .init(state: .init(normal: .custom(id: id))) }
}

