//
// FKRefreshContentView.swift
// FKUIKit — FKRefresh
//
// Protocol for custom indicators (GIF, hosted Lottie view, etc.); optional pull progress callback.
//

import UIKit

/// Protocol for custom refresh / load-more indicators (GIF, hosted Lottie view, etc.).
public protocol FKRefreshContentView: UIView {
  /// Called whenever the control's state changes.
  func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState)
  /// Called continuously while the user pulls the header (`progress` ∈ `[0, 1]` at threshold).
  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat)
}

public extension FKRefreshContentView {
  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {}
}
