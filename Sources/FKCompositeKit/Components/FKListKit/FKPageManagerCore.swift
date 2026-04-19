//
// FKPageManagerCore.swift
// FKUIKit — Pagination
//
// Types for ``FKPageManager``: pagination mode, request parameters, load phase, configuration.
//

import Foundation

// MARK: - Pagination mode

/// Supported server contracts. Default is one-based page indices.
public enum FKPaginationMode: Equatable, Sendable {
  /// `page` query: `firstPageIndex`, `firstPageIndex + 1`, …
  case page(firstPageIndex: Int = 1)
  /// `offset` + `limit`: after each successful batch, offset advances by the fetched count.
  case offset(initialOffset: Int = 0)
}

// MARK: - Request slice

/// Values to map into your API client (query items or body). Exactly one of `page` or `offset` is set.
public struct FKPageRequestParameters: Equatable, Sendable {
  public var page: Int?
  public var offset: Int?
  public var limit: Int

  public init(page: Int?, offset: Int?, limit: Int) {
    self.page = page
    self.offset = offset
    self.limit = limit
  }
}

// MARK: - Load phase (read-only mirror of internal work)

/// What ``FKPageManager`` is doing right now (main-thread semantics).
public enum FKPageLoadPhase: Equatable, Sendable {
  case idle
  /// First visit or hard reload (same paging reset as refresh, different list-state bridge).
  case loadingFirstPage
  case refreshing
  case loadingMore
}

// MARK: - hasMore inference

/// How to derive ``FKPageManager/hasMore`` from the latest batch size alone (no total-count field).
public enum FKPageHasMoreStrategy: Equatable, Sendable {
  /// Finished when the batch is short: `hasMore = (fetchedCount >= pageSize && pageSize > 0)`.
  /// A full batch (or oversized batch) keeps pagination open.
  case fewerThanPageSizeMeansFinished
  /// Stricter: only an exactly full batch keeps pagination open (`hasMore = fetchedCount == pageSize && pageSize > 0`).
  case fullPageMeansMore
}

// MARK: - Configuration

public struct FKPageManagerConfiguration: Equatable, Sendable {
  public var pageSize: Int
  public var mode: FKPaginationMode
  public var hasMoreStrategy: FKPageHasMoreStrategy

  public init(
    pageSize: Int = 20,
    mode: FKPaginationMode = .page(firstPageIndex: 1),
    hasMoreStrategy: FKPageHasMoreStrategy = .fewerThanPageSizeMeansFinished
  ) {
    self.pageSize = max(1, pageSize)
    self.mode = mode
    self.hasMoreStrategy = hasMoreStrategy
  }
}
