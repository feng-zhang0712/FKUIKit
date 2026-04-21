//
// FKSwipeActionConfiguration.swift
//
// Global and per-cell configuration for FKSwipeAction.
//

import UIKit

/// Horizontal swipe trigger area mode.
public enum FKSwipeActionTriggerMode: Hashable, Sendable {
  /// Pan can start from any horizontal location in the host cell.
  case fullWidth
  /// Pan can start near cell edges only.
  ///
  /// - Parameter edgeWidth: Allowed edge trigger width on both sides.
  case edgeOnly(edgeWidth: CGFloat)
}

/// Swipe interaction behavior configuration.
public struct FKSwipeActionBehaviorConfiguration: Hashable {
  /// Enables or disables swipe interaction.
  ///
  /// Default value is `true`.
  public var isEnabled: Bool
  /// Locks the current swipe state and ignores pan gestures.
  public var isLocked: Bool
  /// Trigger mode deciding where horizontal pan can begin.
  public var triggerMode: FKSwipeActionTriggerMode
  /// Whether opening one cell should close others.
  public var allowsOnlyOneOpenCell: Bool
  /// Whether tapping action area mask closes opened state.
  public var closesWhenTapMask: Bool
  /// Whether vertical list scrolling closes opened state.
  public var closesOnScroll: Bool
  /// Whether swipe should bounce when exceeding reveal width.
  public var allowsElasticOverscroll: Bool
  /// Open threshold ratio in `0...1`.
  ///
  /// The default value is `0.35`.
  public var openThresholdRatio: CGFloat
  /// Animation duration for open/close transitions.
  ///
  /// The default value is `0.26`.
  public var animationDuration: TimeInterval

  /// Creates behavior configuration.
  ///
  /// - Parameters:
  ///   - isEnabled: Global interaction switch for this cell.
  ///   - isLocked: Whether swipe state should stay immutable.
  ///   - triggerMode: Gesture trigger strategy.
  ///   - allowsOnlyOneOpenCell: Whether opening should close other cells.
  ///   - closesWhenTapMask: Whether tapping overlay mask closes opened state.
  ///   - closesOnScroll: Whether list scrolling auto closes opened states.
  ///   - allowsElasticOverscroll: Whether reveal can overscroll elastically.
  ///   - openThresholdRatio: Commit threshold ratio when pan ends.
  ///   - animationDuration: Open/close animation duration.
  public init(
    isEnabled: Bool = true,
    isLocked: Bool = false,
    triggerMode: FKSwipeActionTriggerMode = .fullWidth,
    allowsOnlyOneOpenCell: Bool = true,
    closesWhenTapMask: Bool = true,
    closesOnScroll: Bool = true,
    allowsElasticOverscroll: Bool = true,
    openThresholdRatio: CGFloat = 0.35,
    animationDuration: TimeInterval = 0.26
  ) {
    self.isEnabled = isEnabled
    self.isLocked = isLocked
    self.triggerMode = triggerMode
    self.allowsOnlyOneOpenCell = allowsOnlyOneOpenCell
    self.closesWhenTapMask = closesWhenTapMask
    self.closesOnScroll = closesOnScroll
    self.allowsElasticOverscroll = allowsElasticOverscroll
    self.openThresholdRatio = min(max(0.1, openThresholdRatio), 0.9)
    self.animationDuration = max(0.12, animationDuration)
  }
}

/// Visual appearance for swipe container.
public struct FKSwipeActionAppearance {
  /// Area background color under the moving content.
  public var actionAreaBackgroundColor: UIColor
  /// Mask color displayed while opened.
  public var maskColor: UIColor
  /// Spacing between buttons in each side stack.
  public var itemSpacing: CGFloat
  /// Insets applied to left and right button stacks.
  public var actionInsets: UIEdgeInsets

  /// Creates appearance config.
  ///
  /// - Parameters:
  ///   - actionAreaBackgroundColor: Background behind moving foreground content.
  ///   - maskColor: Overlay color visible while opened.
  ///   - itemSpacing: Spacing between adjacent action buttons.
  ///   - actionInsets: Insets applied to left/right action stacks.
  public init(
    actionAreaBackgroundColor: UIColor = .clear,
    maskColor: UIColor = UIColor.black.withAlphaComponent(0.05),
    itemSpacing: CGFloat = 0,
    actionInsets: UIEdgeInsets = .zero
  ) {
    self.actionAreaBackgroundColor = actionAreaBackgroundColor
    self.maskColor = maskColor
    self.itemSpacing = max(0, itemSpacing)
    self.actionInsets = actionInsets
  }
}

/// Full configuration for one cell swipe setup.
public struct FKSwipeActionConfiguration {
  /// Actions revealed by swiping content to the right.
  public var leftActions: [FKSwipeActionItem]
  /// Actions revealed by swiping content to the left.
  public var rightActions: [FKSwipeActionItem]
  /// Interaction behavior.
  public var behavior: FKSwipeActionBehaviorConfiguration
  /// Visual appearance.
  public var appearance: FKSwipeActionAppearance

  /// Creates one full cell configuration.
  ///
  /// - Parameters:
  ///   - leftActions: Buttons revealed when swiping to the right.
  ///   - rightActions: Buttons revealed when swiping to the left.
  ///   - behavior: Interaction behavior for this host cell.
  ///   - appearance: Visual appearance for action background and mask.
  public init(
    leftActions: [FKSwipeActionItem] = [],
    rightActions: [FKSwipeActionItem] = [],
    behavior: FKSwipeActionBehaviorConfiguration = FKSwipeActionBehaviorConfiguration(),
    appearance: FKSwipeActionAppearance = FKSwipeActionAppearance()
  ) {
    self.leftActions = leftActions
    self.rightActions = rightActions
    self.behavior = behavior
    self.appearance = appearance
  }
}

/// Context passed to action callbacks.
public struct FKSwipeActionContext {
  /// Host cell.
  public weak var cell: UIView?
  /// Host scroll view (`UITableView` or `UICollectionView`).
  public weak var scrollView: UIScrollView?
  /// Action that is triggered.
  public let item: FKSwipeActionItem
  /// Action index in its side array.
  public let index: Int
  /// Side where this action resides.
  public let side: FKSwipeActionSide

  /// Creates callback context.
  ///
  /// - Parameters:
  ///   - cell: Host cell view associated with the callback.
  ///   - scrollView: Parent list container, if available.
  ///   - item: Action item that was tapped.
  ///   - index: Position index of the tapped item in its side array.
  ///   - side: Side that owns the tapped action.
  public init(
    cell: UIView?,
    scrollView: UIScrollView?,
    item: FKSwipeActionItem,
    index: Int,
    side: FKSwipeActionSide
  ) {
    self.cell = cell
    self.scrollView = scrollView
    self.item = item
    self.index = index
    self.side = side
  }
}

/// Side of action reveal.
public enum FKSwipeActionSide: Hashable, Sendable {
  /// Reveals buttons on the leading/left side.
  case left
  /// Reveals buttons on the trailing/right side.
  case right
}
