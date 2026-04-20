//
// FKRefreshManager.swift
// FKUIKit — FKRefresh
//
// Singleton manager for global style / behaviour overrides.
//

import UIKit

/// Global manager that centralizes FKRefresh default configuration.
@MainActor
public final class FKRefreshManager {

  /// Shared singleton instance.
  public static let shared = FKRefreshManager()

  private init() {}

  /// Applies global pull-to-refresh and load-more defaults.
  /// - Parameters:
  ///   - pullToRefresh: Global default used when pull configuration is omitted.
  ///   - loadMore: Global default used when load-more configuration is omitted.
  public func applyGlobalConfiguration(
    pullToRefresh: FKRefreshConfiguration,
    loadMore: FKRefreshConfiguration
  ) {
    FKRefreshSettings.pullToRefresh = pullToRefresh
    FKRefreshSettings.loadMore = loadMore
  }

  /// Updates pull-to-refresh global configuration in place.
  /// - Parameter update: Mutation closure for current pull configuration.
  public func updatePullToRefreshConfiguration(_ update: (inout FKRefreshConfiguration) -> Void) {
    var config = FKRefreshSettings.pullToRefresh
    update(&config)
    FKRefreshSettings.pullToRefresh = config
  }

  /// Updates load-more global configuration in place.
  /// - Parameter update: Mutation closure for current load-more configuration.
  public func updateLoadMoreConfiguration(_ update: (inout FKRefreshConfiguration) -> Void) {
    var config = FKRefreshSettings.loadMore
    update(&config)
    FKRefreshSettings.loadMore = config
  }
}
