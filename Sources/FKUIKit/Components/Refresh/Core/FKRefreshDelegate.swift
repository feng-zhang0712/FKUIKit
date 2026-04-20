//
// FKRefreshDelegate.swift
// FKUIKit — FKRefresh
//
// Optional delegate alternative to `FKRefreshControl.onStateChanged` (callbacks on the main queue).
//

import UIKit

/// Optional delegate for hosts that prefer protocols over closures.
public protocol FKRefreshControlDelegate: AnyObject {
  /// Invoked on every state transition (always main queue).
  func refreshControl(_ control: FKRefreshControl, didChange state: FKRefreshState, from previous: FKRefreshState)
}

public extension FKRefreshControlDelegate {
  func refreshControl(_ control: FKRefreshControl, didChange state: FKRefreshState, from previous: FKRefreshState) {}
}
