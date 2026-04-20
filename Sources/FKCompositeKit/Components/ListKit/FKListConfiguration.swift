//
// FKListConfiguration.swift
// FKCompositeKit — FKListKit
//
// Unified feature flags and styling hooks for ``FKListPlugin``.
//

import Foundation
import UIKit
import FKUIKit

/// Feature and presentation configuration for a single ``FKListPlugin`` instance.
///
/// Keep a copy per screen or per plugin; mutating after ``FKListPlugin/attach`` requires calling
/// ``FKListPlugin/applyConfiguration(_:)`` so internal coordinators stay in sync.
public struct FKListConfiguration {

  // MARK: Pagination

  /// Underlying page / offset contract for ``FKPageManager``.
  public var pagination: FKPageManagerConfiguration

  /// When non-`nil`, overrides ``FKPageManagerConfiguration/hasMoreStrategy`` for inferring ``hasMore``.
  public var hasMoreEvaluator: ((_ fetchedCount: Int, _ pageSize: Int) -> Bool)?

  // MARK: Chrome toggles

  public var enablesPullToRefresh: Bool
  public var enablesLoadMore: Bool

  /// When `true` **and** a skeleton driver is supplied at attach-time, first paint uses ``FKListLoadingKind/initial``.
  /// If no skeleton host is attached, the plugin automatically falls back to silent loading (no hidden list).
  public var enablesSkeletonOnInitialLoad: Bool

  /// Controls whether ``FKEmptyState`` is shown for the zero-row success path.
  public var presentsEmptyStateOverlay: Bool
  /// Controls whether ``FKEmptyState`` is shown for hard errors (not load-more failures).
  public var presentsErrorStateOverlay: Bool

  /// When `true`, the scroll view stays visible under the empty overlay (table “empty” design).
  public var keepsListVisibleWhenEmpty: Bool
  /// When `true`, the scroll view stays visible under a full-screen error overlay (toast-first flows).
  public var keepsListVisibleWhenError: Bool

  // MARK: Refresh failure UX

  /// When `true`, the plugin forwards ``FKListPlugin/currentTotalItemCount()`` into ``FKPageManager`` so a failed
  /// pull-to-refresh can become ``FKListState/loadMoreFailed`` instead of ``FKListState/error`` when rows existed.
  public var tracksItemCountForRefreshFailureUX: Bool

  // MARK: Advanced

  /// Models and overlay policy forwarded to ``FKListStateManager`` (empty / error copy, etc.).
  public var listStateManagerConfiguration: FKListStateManagerConfiguration

  /// Optional per-control styling; `nil` merges ``FKRefreshSettings`` at attach time.
  public var pullToRefreshConfiguration: FKRefreshConfiguration?
  public var loadMoreConfiguration: FKRefreshConfiguration?

  // MARK: Init

  public init(
    pagination: FKPageManagerConfiguration = FKPageManagerConfiguration(),
    hasMoreEvaluator: ((_ fetchedCount: Int, _ pageSize: Int) -> Bool)? = nil,
    enablesPullToRefresh: Bool = true,
    enablesLoadMore: Bool = true,
    enablesSkeletonOnInitialLoad: Bool = true,
    presentsEmptyStateOverlay: Bool = true,
    presentsErrorStateOverlay: Bool = true,
    keepsListVisibleWhenEmpty: Bool = false,
    keepsListVisibleWhenError: Bool = false,
    tracksItemCountForRefreshFailureUX: Bool = true,
    listStateManagerConfiguration: FKListStateManagerConfiguration = FKListStateManagerConfiguration(),
    pullToRefreshConfiguration: FKRefreshConfiguration? = nil,
    loadMoreConfiguration: FKRefreshConfiguration? = nil
  ) {
    self.pagination = pagination
    self.hasMoreEvaluator = hasMoreEvaluator
    self.enablesPullToRefresh = enablesPullToRefresh
    self.enablesLoadMore = enablesLoadMore
    self.enablesSkeletonOnInitialLoad = enablesSkeletonOnInitialLoad
    self.presentsEmptyStateOverlay = presentsEmptyStateOverlay
    self.presentsErrorStateOverlay = presentsErrorStateOverlay
    self.keepsListVisibleWhenEmpty = keepsListVisibleWhenEmpty
    self.keepsListVisibleWhenError = keepsListVisibleWhenError
    self.tracksItemCountForRefreshFailureUX = tracksItemCountForRefreshFailureUX
    self.listStateManagerConfiguration = listStateManagerConfiguration
    self.pullToRefreshConfiguration = pullToRefreshConfiguration
    self.loadMoreConfiguration = loadMoreConfiguration
  }

  // MARK: Internal merge

  func resolvedListStateManagerConfiguration() -> FKListStateManagerConfiguration {
    var merged = listStateManagerConfiguration
    merged.presentsEmptyOverlay = presentsEmptyStateOverlay
    merged.presentsErrorOverlay = presentsErrorStateOverlay
    merged.keepsListVisibleOnEmpty = keepsListVisibleWhenEmpty
    merged.keepsListVisibleOnError = keepsListVisibleWhenError
    return merged
  }
}
