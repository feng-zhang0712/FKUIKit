//
// FKPageManager.swift
// FKUIKit — Pagination
//
// Pure pagination coordinator: cursors, hasMore, duplicate guards, optional ``FKListStateManager`` bridge.
//

import UIKit

/// Orchestrates page / offset cursors, `hasMore`, and load phases without touching scroll views or refresh controls.
@MainActor
public final class FKPageManager {

  // MARK: - Configuration

  public var configuration: FKPageManagerConfiguration {
    didSet { configuration.pageSize = max(1, configuration.pageSize) }
  }

  /// Overrides ``FKPageManagerConfiguration/hasMoreStrategy`` when set (main-thread only).
  public var hasMoreEvaluator: ((_ fetchedCount: Int, _ pageSize: Int) -> Bool)?

  // MARK: - Optional list-state bridge (weak — screen owns both objects)

  public weak var listStateManager: FKListStateManager?
  /// When `true`, successful / failed completions forward to ``FKListStateManager/setState(_:animated:)``.
  public var automaticallyUpdatesListState: Bool = false
  /// List presentation while ``beginInitialLoad`` runs with ``automaticallyUpdatesListState`` (skeleton vs silent).
  public var initialLoadListPresentation: FKListLoadingKind = .initial

  // MARK: - Callbacks (always invoked on the main queue)

  public var onInitialLoadStarted: (() -> Void)?
  public var onRefreshStarted: (() -> Void)?
  public var onLoadMoreStarted: (() -> Void)?
  /// Fired after any path resolves loading flags back to idle (success, empty, error, or cancelled in-flight).
  public var onAnyLoadFinished: (() -> Void)?
  /// `hasMore` flipped from `true` → `false` after a successful fetch.
  public var onNoMoreData: (() -> Void)?

  // MARK: - Public state (read on the main thread)

  public private(set) var loadPhase: FKPageLoadPhase = .idle
  public private(set) var hasMore: Bool = true
  /// Sum of `fetchedCount` across successful batches since last reset.
  public private(set) var accumulatedFetchedCount: Int = 0

  /// One-based page index of the **last fully successful** page request (`nil` until the first success in this session).
  public private(set) var lastSuccessfulPage: Int?
  /// Next offset for `.offset` mode after the last successful batch (`initialOffset` until the first success).
  public private(set) var nextRequestOffset: Int

  // MARK: - Private

  private var isLoading: Bool = false
  private var firstPageIndex: Int {
    switch configuration.mode {
    case .page(let first): return first
    case .offset: return 0
    }
  }

  private var initialOffset: Int {
    switch configuration.mode {
    case .page: return 0
    case .offset(let initial): return initial
    }
  }

  // MARK: - Init

  public init(configuration: FKPageManagerConfiguration = FKPageManagerConfiguration()) {
    self.configuration = configuration
    self.nextRequestOffset = {
      switch configuration.mode {
      case .page: return 0
      case .offset(let initial): return initial
      }
    }()
  }

  // MARK: - One-shot queries

  /// `true` when another page might exist and no request is in flight.
  public var canLoadMore: Bool {
    performOnMain { self.hasMore && !self.isLoading && self.hasCompletedFirstSuccessfulPageLocked }
  }

  /// `true` when idle (no first-page / refresh / load-more in flight).
  public var isIdle: Bool {
    performOnMain { !self.isLoading }
  }

  // MARK: - Begin requests

  /// Clears paging, sets phase to ``FKPageLoadPhase/loadingFirstPage``, and returns the first slice to fetch.
  /// Returns `nil` when a load is already in flight (duplicate guard).
  @discardableResult
  public func beginInitialLoad() -> FKPageRequestParameters? {
    performOnMain {
      guard !self.isLoading else { return nil }
      self.resetPagingLocked()
      self.isLoading = true
      self.loadPhase = .loadingFirstPage
      self.onInitialLoadStarted?()
      if self.automaticallyUpdatesListState, let list = self.listStateManager {
        list.setState(.loading(self.initialLoadListPresentation))
      }
      return self.makeFirstPageParametersLocked()
    }
  }

  /// Resets paging like the first page, marks ``FKPageLoadPhase/refreshing``, and returns the first slice.
  @discardableResult
  public func beginRefresh() -> FKPageRequestParameters? {
    performOnMain {
      guard !self.isLoading else { return nil }
      self.resetPagingLocked()
      self.isLoading = true
      self.loadPhase = .refreshing
      self.onRefreshStarted?()
      if self.automaticallyUpdatesListState, let list = self.listStateManager {
        list.setState(.refreshing)
      }
      return self.makeFirstPageParametersLocked()
    }
  }

  /// Advances only after a successful batch; returns the next slice or `nil` if `hasMore` is false or a load is active.
  @discardableResult
  public func beginLoadMore() -> FKPageRequestParameters? {
    performOnMain {
      guard !self.isLoading, self.hasMore, self.hasCompletedFirstSuccessfulPageLocked else { return nil }
      self.isLoading = true
      self.loadPhase = .loadingMore
      self.onLoadMoreStarted?()
      return self.makeNextPageParametersLocked()
    }
  }

  // MARK: - Complete requests

  /// Finishes a first-page / refresh request. Always clears the in-flight flag on the main thread.
  /// - Parameter totalItemCountAfterMerge: Pass your merged UI count; omit to use this batch size only (same as `fetchedCount` after reset).
  /// - Parameter itemCountBeforeRefresh: When a **pull-to-refresh** request fails and this value is `> 0`, list UI shows ``FKListState/loadMoreFailed`` instead of a full-screen ``FKListState/error``.
  public func completeFirstPage(
    fetchedCount: Int,
    totalItemCountAfterMerge: Int? = nil,
    error: Error?,
    listError: FKListDisplayedError? = nil,
    itemCountBeforeRefresh: Int? = nil,
    animated: Bool = true
  ) {
    performOnMain {
      guard self.loadPhase == .loadingFirstPage || self.loadPhase == .refreshing else { return }
      let count = max(0, fetchedCount)
      defer {
        self.isLoading = false
        self.loadPhase = .idle
        self.onAnyLoadFinished?()
      }
      if let error {
        self.hasMore = true
        if self.automaticallyUpdatesListState, let list = self.listStateManager {
          let mapped = listError ?? FKListDisplayedError.resolve(from: error)
          let retained = itemCountBeforeRefresh ?? 0
          if self.loadPhase == .refreshing, retained > 0 {
            list.setState(.loadMoreFailed(mapped), animated: animated)
          } else {
            list.setState(.error(mapped), animated: animated)
          }
        }
        return
      }
      self.applyFirstPageSuccessLocked(fetchedCount: count)
      let totalForList = totalItemCountAfterMerge ?? self.accumulatedFetchedCount
      self.pushListStateAfterFirstPage(
        totalItemCountAfterMerge: totalForList,
        animated: animated
      )
    }
  }

  /// Finishes a load-more request. Failures do **not** advance cursors (implicit page / offset rollback).
  /// - Parameter totalItemCountAfterMerge: Pass your merged UI count; omit to use the running ``accumulatedFetchedCount`` after success.
  public func completeLoadMore(
    fetchedCount: Int,
    totalItemCountAfterMerge: Int? = nil,
    error: Error?,
    listError: FKListDisplayedError? = nil,
    animated: Bool = true
  ) {
    performOnMain {
      guard self.loadPhase == .loadingMore else { return }
      let count = max(0, fetchedCount)
      defer {
        self.isLoading = false
        self.loadPhase = .idle
        self.onAnyLoadFinished?()
      }
      if let error {
        if self.automaticallyUpdatesListState, let list = self.listStateManager {
          let mapped = listError ?? FKListDisplayedError.resolve(from: error)
          let existingItems = totalItemCountAfterMerge ?? self.accumulatedFetchedCount
          if existingItems > 0 {
            list.setState(.loadMoreFailed(mapped), animated: animated)
          } else {
            list.setState(.error(mapped), animated: animated)
          }
        }
        return
      }
      let hadMore = self.hasMore
      self.applyLoadMoreSuccessLocked(fetchedCount: count)
      if hadMore && !self.hasMore {
        self.onNoMoreData?()
      }
      if self.automaticallyUpdatesListState, let list = self.listStateManager {
        let totalForList = totalItemCountAfterMerge ?? self.accumulatedFetchedCount
        let snapshot = FKListContentSnapshot(itemCount: totalForList, hasMorePages: self.hasMore)
        list.setState(.content(snapshot), animated: animated)
      }
    }
  }

  // MARK: - Reset

  /// Clears cursors and flags as if the screen just appeared (does not start a fetch).
  public func resetPagingToInitial() {
    performOnMain {
      self.resetPagingLocked()
      self.isLoading = false
      self.loadPhase = .idle
    }
  }

  /// Full reset plus optional list idle state.
  public func resetEverything(animated: Bool = true) {
    performOnMain {
      self.resetPagingLocked()
      self.isLoading = false
      self.loadPhase = .idle
      if self.automaticallyUpdatesListState, let list = self.listStateManager {
        list.setState(.idle, animated: animated)
      }
    }
  }

  /// Drops the in-flight guard without advancing cursors (e.g. task cancellation). Prefer paired `complete*` when possible.
  public func abandonInFlightRequest() {
    performOnMain {
      guard self.isLoading else { return }
      self.isLoading = false
      self.loadPhase = .idle
      self.onAnyLoadFinished?()
    }
  }

  // MARK: - Main queue

  private func performOnMain<T>(_ work: () -> T) -> T {
    if Thread.isMainThread {
      return work()
    }
    var result: T!
    DispatchQueue.main.sync {
      result = work()
    }
    return result
  }

  /// `true` once the first page has succeeded at least once in this paging session (guards premature load-more).
  private var hasCompletedFirstSuccessfulPageLocked: Bool {
    switch configuration.mode {
    case .page:
      return lastSuccessfulPage != nil
    case .offset:
      return accumulatedFetchedCount > 0
    }
  }

  // MARK: - Paging internals

  private func resetPagingLocked() {
    lastSuccessfulPage = nil
    accumulatedFetchedCount = 0
    hasMore = true
    nextRequestOffset = initialOffset
  }

  private func makeFirstPageParametersLocked() -> FKPageRequestParameters {
    let limit = configuration.pageSize
    switch configuration.mode {
    case .page(let first):
      return FKPageRequestParameters(page: first, offset: nil, limit: limit)
    case .offset:
      return FKPageRequestParameters(page: nil, offset: nextRequestOffset, limit: limit)
    }
  }

  private func makeNextPageParametersLocked() -> FKPageRequestParameters {
    let limit = configuration.pageSize
    switch configuration.mode {
    case .page:
      let nextPage = (lastSuccessfulPage ?? (firstPageIndex - 1)) + 1
      return FKPageRequestParameters(page: nextPage, offset: nil, limit: limit)
    case .offset:
      return FKPageRequestParameters(page: nil, offset: nextRequestOffset, limit: limit)
    }
  }

  private func applyFirstPageSuccessLocked(fetchedCount: Int) {
    accumulatedFetchedCount = fetchedCount
    switch configuration.mode {
    case .page(let first):
      lastSuccessfulPage = first
    case .offset:
      nextRequestOffset = initialOffset + fetchedCount
    }
    hasMore = evaluateHasMore(fetchedCount: fetchedCount)
  }

  private func applyLoadMoreSuccessLocked(fetchedCount: Int) {
    accumulatedFetchedCount += fetchedCount
    switch configuration.mode {
    case .page:
      if let last = lastSuccessfulPage {
        lastSuccessfulPage = last + 1
      } else {
        lastSuccessfulPage = firstPageIndex
      }
    case .offset:
      nextRequestOffset += fetchedCount
    }
    hasMore = evaluateHasMore(fetchedCount: fetchedCount)
  }

  private func evaluateHasMore(fetchedCount: Int) -> Bool {
    if let hasMoreEvaluator {
      return hasMoreEvaluator(fetchedCount, configuration.pageSize)
    }
    let pageSize = configuration.pageSize
    guard pageSize > 0 else { return false }
    switch configuration.hasMoreStrategy {
    case .fewerThanPageSizeMeansFinished:
      return fetchedCount >= pageSize
    case .fullPageMeansMore:
      return fetchedCount == pageSize
    }
  }

  private func pushListStateAfterFirstPage(totalItemCountAfterMerge: Int, animated: Bool) {
    guard automaticallyUpdatesListState, let list = listStateManager else { return }
    if totalItemCountAfterMerge <= 0 {
      list.setState(.empty, animated: animated)
    } else {
      let snapshot = FKListContentSnapshot(itemCount: totalItemCountAfterMerge, hasMorePages: hasMore)
      list.setState(.content(snapshot), animated: animated)
    }
  }
}
