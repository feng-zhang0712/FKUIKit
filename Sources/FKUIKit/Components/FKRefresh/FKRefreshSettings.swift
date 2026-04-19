//
// FKRefreshSettings.swift
// FKUIKit — FKRefresh
//
// Module-level defaults for `fk_addPullToRefresh` / `fk_addLoadMore` when configuration is omitted.
// Mutate from the main thread only (`nonisolated(unsafe)` for Swift 6).
//

import UIKit

/// Global appearance defaults for FKRefresh.
public enum FKRefreshSettings {

  /// Default used by `fk_addPullToRefresh` when `configuration` is `nil`.
  public nonisolated(unsafe) static var pullToRefresh: FKRefreshConfiguration = .default

  /// Default used by `fk_addLoadMore` when `configuration` is `nil`.
  public nonisolated(unsafe) static var loadMore: FKRefreshConfiguration = .default
}
