//
// FKSkeletonDisplayOptions.swift
//

import UIKit

/// Runtime options for showing skeletons on a view tree.
public struct FKSkeletonDisplayOptions {
  /// Whether touches should be blocked while skeleton is visible.
  public var blocksInteraction: Bool
  /// Whether target views should be visually hidden while their skeleton is displayed.
  public var hidesTargetView: Bool
  /// Views that should not receive generated skeletons.
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
