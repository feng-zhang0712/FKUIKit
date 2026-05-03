import UIKit

/// Options applied when scanning a subtree with ``UIView/fk_showAutoSkeleton(configuration:options:animated:)``.
public struct FKSkeletonDisplayOptions {
  /// When `true`, the host view stops delivering touches to its subtree while placeholders are visible.
  public var blocksInteraction: Bool
  /// When `true`, matched leaf views fade out (`alpha = 0`) while placeholders sit above them.
  public var hidesTargetView: Bool
  /// Views excluded by identity from placeholder generation (use with ``UIView/fk_isSkeletonExcluded`` for subtree flags).
  public var excludedViews: [UIView]

  public init(
    blocksInteraction: Bool = true,
    hidesTargetView: Bool = true,
    excludedViews: [UIView] = []
  ) {
    self.blocksInteraction = blocksInteraction
    self.hidesTargetView = hidesTargetView
    self.excludedViews = excludedViews
  }
}
