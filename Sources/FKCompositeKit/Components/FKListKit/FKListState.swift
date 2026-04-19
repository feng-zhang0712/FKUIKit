//
// FKListState.swift
// FKCompositeKit — FKListKit
//
// Canonical list presentation states shared by ``FKListStateManager`` and ``FKListPlugin``.
//

import Foundation

// MARK: - List state

/// Canonical list-page states for coordinating skeletons, overlays, the primary list surface, and refresh footers.
///
/// ## Mapping to product language
/// - **idle**: no work, chrome quiet.
/// - **loading**: first load / hard reload (skeleton vs silent via ``FKListLoadingKind``).
/// - **refreshing**: pull-to-refresh path (list stays visible).
/// - **success**: use ``FKListState/content`` or the ``success(itemCount:hasMorePages:)`` factory.
/// - **empty** / **error**: terminal overlays for zero rows or hard failures.
public enum FKListState: Equatable {
  /// Baseline before the first explicit transition; overlays off, refresh quiet.
  case idle
  /// Work in flight for the first page or a full reload.
  case loading(FKListLoadingKind)
  /// Pull-to-refresh path: list stays visible; avoids stacking a second loading curtain.
  case refreshing
  /// At least one row after a successful fetch (the **success** presentation).
  case content(FKListContentSnapshot)
  /// Successful fetch with zero rows (distinct from transport errors).
  case empty
  /// First-page / full-screen failure: replaces the list with an error overlay.
  case error(FKListDisplayedError)
  /// Pagination failure while rows already exist: keep the list, only finish the footer.
  case loadMoreFailed(FKListDisplayedError)

  // MARK: Success shorthand

  /// Successful list with data: equivalent to ``FKListState/content`` with a fresh ``FKListContentSnapshot``.
  public static func success(itemCount: Int, hasMorePages: Bool = true) -> FKListState {
    .content(FKListContentSnapshot(itemCount: itemCount, hasMorePages: hasMorePages))
  }
}
