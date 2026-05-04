import UIKit
import FKUIKit

/// Configuration for ``FKAnchoredDropdownController``.
public struct FKAnchoredDropdownConfiguration {
  /// How the component switches tabs while a panel stays presented.
  public enum SwitchAnimationStyle: Equatable, Sendable {
    /// Dismiss, then present again (uses full ``FKPresentationController`` transitions).
    case dismissThenPresent(dismissAnimated: Bool, presentAnimated: Bool)

    /// Replace only the content; backdrop and shell stay visible.
    case replaceInPlace(animation: ReplaceInPlaceAnimation)
  }

  /// Animation for ``SwitchAnimationStyle/replaceInPlace(animation:)``.
  public enum ReplaceInPlaceAnimation: Equatable, Sendable {
    case crossfade(duration: TimeInterval)
    case slideVertical(direction: SlideDirection, duration: TimeInterval)

    public enum SlideDirection: Equatable, Sendable {
      case up
      case down
    }
  }

  /// Policy for retaining built ``UIViewController`` instances per tab.
  public enum ContentCachingPolicy: Equatable, Sendable {
    case recreate
    case cachePerTab
  }

  /// Durations used when the presented shell asks ``FKPresentationController`` to relayout after
  /// content height changes (``preferredContentSize`` / in-place tab switch completion).
  ///
  /// This is separate from ``SwitchAnimationStyle`` crossfade/slide durations, which only affect
  /// the inner content container, not the anchor-attached frame.
  public struct PresentationLayoutAnimation: Equatable, Sendable {
    public var duration: TimeInterval

    public init(duration: TimeInterval = 0.24) {
      self.duration = duration
    }
  }

  /// Lifecycle hooks (optional). Prefer this over subclassing.
  public struct Events<TabID: Hashable> {
    public var onStateChange: (@MainActor (_ state: FKAnchoredDropdownController<TabID>.State) -> Void)?
    public var onExpandedTabChange: (@MainActor (_ expandedTab: TabID?) -> Void)?
    public var onWillExpand: (@MainActor (_ tab: TabID) -> Void)?
    public var onDidExpand: (@MainActor (_ tab: TabID) -> Void)?
    public var onWillCollapse: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.DismissReason) -> Void)?
    public var onDidCollapse: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.DismissReason) -> Void)?
    public var onWillSwitchTab: (@MainActor (_ from: TabID, _ to: TabID) -> Void)?
    public var onDidSwitchTab: (@MainActor (_ from: TabID, _ to: TabID) -> Void)?

    public init(
      onStateChange: (@MainActor (_ state: FKAnchoredDropdownController<TabID>.State) -> Void)? = nil,
      onExpandedTabChange: (@MainActor (_ expandedTab: TabID?) -> Void)? = nil,
      onWillExpand: (@MainActor (_ tab: TabID) -> Void)? = nil,
      onDidExpand: (@MainActor (_ tab: TabID) -> Void)? = nil,
      onWillCollapse: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.DismissReason) -> Void)? = nil,
      onDidCollapse: (@MainActor (_ tab: TabID?, _ reason: FKAnchoredDropdownController<TabID>.DismissReason) -> Void)? = nil,
      onWillSwitchTab: (@MainActor (_ from: TabID, _ to: TabID) -> Void)? = nil,
      onDidSwitchTab: (@MainActor (_ from: TabID, _ to: TabID) -> Void)? = nil
    ) {
      self.onStateChange = onStateChange
      self.onExpandedTabChange = onExpandedTabChange
      self.onWillExpand = onWillExpand
      self.onDidExpand = onDidExpand
      self.onWillCollapse = onWillCollapse
      self.onDidCollapse = onDidCollapse
      self.onWillSwitchTab = onWillSwitchTab
      self.onDidSwitchTab = onDidSwitchTab
    }
  }

  public var tabBarConfiguration: FKTabBarConfiguration
  /// Dismiss behavior, backdrop, keyboard, and other presentation options. Layout is always anchor; the host overwrites `layout` when presenting.
  public var presentationConfiguration: FKPresentationConfiguration
  public var switchAnimationStyle: SwitchAnimationStyle
  public var contentCachingPolicy: ContentCachingPolicy
  /// Anchor presentation relayout animation after content size / tab content changes.
  public var presentationLayoutAnimation: PresentationLayoutAnimation
  /// Optional custom anchor; when `nil`, the tab bar is the source and the tab bar host view is the overlay container.
  public var anchorPlacement: FKAnchoredDropdownAnchorPlacement?

  public init(
    tabBarConfiguration: FKTabBarConfiguration = FKAnchoredDropdownConfiguration.default.tabBarConfiguration,
    presentationConfiguration: FKPresentationConfiguration = FKAnchoredDropdownConfiguration.default.presentationConfiguration,
    switchAnimationStyle: SwitchAnimationStyle = .replaceInPlace(animation: .crossfade(duration: 0.18)),
    contentCachingPolicy: ContentCachingPolicy = .cachePerTab,
    presentationLayoutAnimation: PresentationLayoutAnimation = PresentationLayoutAnimation(),
    anchorPlacement: FKAnchoredDropdownAnchorPlacement? = nil
  ) {
    self.tabBarConfiguration = tabBarConfiguration
    self.presentationConfiguration = presentationConfiguration
    self.switchAnimationStyle = switchAnimationStyle
    self.contentCachingPolicy = contentCachingPolicy
    self.presentationLayoutAnimation = presentationLayoutAnimation
    self.anchorPlacement = anchorPlacement
  }
}
