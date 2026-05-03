import UIKit
import FKUIKit

/// Configuration for `FKAnchoredDropdownController`.
public struct FKAnchoredDropdownConfiguration {
  /// How the component switches between two different tabs while the dropdown is visible.
  public enum SwitchAnimationStyle: Equatable, Sendable {
    /// Dismiss the current dropdown then present the new dropdown.
    ///
    /// - Note: This style prioritizes correctness and uses `FKPresentationController` transitions.
    case dismissThenPresent(dismissAnimated: Bool, presentAnimated: Bool)

    /// Keeps the presentation container and backdrop, and only replaces the content in place.
    ///
    /// This style typically yields less flicker and more "app-native" tab switching.
    case replaceInPlace(animation: ReplaceInPlaceAnimation)
  }

  /// Animation used by `.replaceInPlace`.
  public enum ReplaceInPlaceAnimation: Equatable, Sendable {
    /// Crossfade old/new content.
    case crossfade(duration: TimeInterval)
    /// Slides content vertically.
    case slideVertical(direction: SlideDirection, duration: TimeInterval)

    public enum SlideDirection: Equatable, Sendable {
      case up
      case down
    }
  }

  /// Content controller caching policy.
  public enum ContentCachingPolicy: Equatable, Sendable {
    /// Always create a new content controller when presenting.
    case recreate
    /// Cache one controller instance per tab id (recommended for heavy views).
    case cachePerTab
  }

  /// Hooks for state changes.
  public struct Callbacks<TabID: Hashable> {
    /// Called whenever the internal state changes.
    public var stateDidChange: (@MainActor (_ state: FKAnchoredDropdownController<TabID>.State) -> Void)?
    /// Called whenever the expanded tab id changes.
    public var expandedTabDidChange: (@MainActor (_ expandedTab: TabID?) -> Void)?
    public var willOpen: (@MainActor (_ tab: TabID) -> Void)?
    public var didOpen: (@MainActor (_ tab: TabID) -> Void)?
    public var willClose: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.CloseReason) -> Void)?
    public var didClose: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.CloseReason) -> Void)?
    public var willSwitch: (@MainActor (_ from: TabID, _ to: TabID) -> Void)?
    public var didSwitch: (@MainActor (_ from: TabID, _ to: TabID) -> Void)?

    public init(
      stateDidChange: (@MainActor (_ state: FKAnchoredDropdownController<TabID>.State) -> Void)? = nil,
      expandedTabDidChange: (@MainActor (_ expandedTab: TabID?) -> Void)? = nil,
      willOpen: (@MainActor (_ tab: TabID) -> Void)? = nil,
      didOpen: (@MainActor (_ tab: TabID) -> Void)? = nil,
      willClose: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.CloseReason) -> Void)? = nil,
      didClose: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.CloseReason) -> Void)? = nil,
      willSwitch: (@MainActor (_ from: TabID, _ to: TabID) -> Void)? = nil,
      didSwitch: (@MainActor (_ from: TabID, _ to: TabID) -> Void)? = nil
    ) {
      self.stateDidChange = stateDidChange
      self.expandedTabDidChange = expandedTabDidChange
      self.willOpen = willOpen
      self.didOpen = didOpen
      self.willClose = willClose
      self.didClose = didClose
      self.willSwitch = willSwitch
      self.didSwitch = didSwitch
    }
  }

  /// Underlying `FKTabBar` configuration to use.
  public var tabBarConfiguration: FKTabBarConfiguration
  /// Underlying `FKPresentationController` configuration to use.
  ///
  /// The component always uses `FKPresentationConfiguration.Layout.anchor(_:)` for layout;
  /// the concrete anchor is derived from ``anchorOverride`` (if any) and the tab bar host.
  public var presentationConfiguration: FKPresentationConfiguration
  /// Animation style when switching between two tabs while expanded.
  public var switchAnimationStyle: SwitchAnimationStyle
  /// Content controller caching policy.
  public var contentCachingPolicy: ContentCachingPolicy
  /// Whether tapping the backdrop should close the dropdown.
  ///
  /// - Note: This maps to `presentationConfiguration.dismissBehavior`.
  public var allowsBackdropTapToDismiss: Bool
  /// Whether swipe-to-dismiss should be enabled.
  ///
  /// - Note: This maps to `presentationConfiguration.dismissBehavior`.
  public var allowsSwipeToDismiss: Bool
  /// Whether tapping outside content (within allowed mask area) should dismiss.
  ///
  /// - Note: This maps to `presentationConfiguration.dismissBehavior`.
  public var allowsTapOutsideToDismiss: Bool

  /// Optional custom anchor placement.
  ///
  /// When `nil`, the dropdown attaches to ``FKAnchoredDropdownTabBarHost/tabBar`` and hosts inside
  /// the tab bar host’s root view (recommended default).
  public var anchorOverride: FKAnchoredDropdownAnchorOverride?

  public init(
    tabBarConfiguration: FKTabBarConfiguration = FKAnchoredDropdownConfiguration.default.tabBarConfiguration,
    presentationConfiguration: FKPresentationConfiguration = FKAnchoredDropdownConfiguration.default.presentationConfiguration,
    switchAnimationStyle: SwitchAnimationStyle = .dismissThenPresent(dismissAnimated: false, presentAnimated: true),
    contentCachingPolicy: ContentCachingPolicy = .cachePerTab,
    allowsBackdropTapToDismiss: Bool = true,
    allowsSwipeToDismiss: Bool = true,
    allowsTapOutsideToDismiss: Bool = true,
    anchorOverride: FKAnchoredDropdownAnchorOverride? = nil
  ) {
    self.tabBarConfiguration = tabBarConfiguration
    self.presentationConfiguration = presentationConfiguration
    self.switchAnimationStyle = switchAnimationStyle
    self.contentCachingPolicy = contentCachingPolicy
    self.allowsBackdropTapToDismiss = allowsBackdropTapToDismiss
    self.allowsSwipeToDismiss = allowsSwipeToDismiss
    self.allowsTapOutsideToDismiss = allowsTapOutsideToDismiss
    self.anchorOverride = anchorOverride
  }
}
