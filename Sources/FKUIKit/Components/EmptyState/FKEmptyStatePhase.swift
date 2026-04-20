//
// FKEmptyStatePhase.swift
//
// High-level state machine for page placeholders: normal content vs loading / empty / error overlays.
//

import Foundation

// MARK: - Phase

/// The four presentation modes for `FKEmptyState` overlays.
///
/// Map your view-model state to a phase, then build an `FKEmptyStateModel` with the same `phase`.
///
/// - Note: Use `.content` with `UIView.fk_applyEmptyState` to hide the overlay without removing the view (avoids flicker).
public enum FKEmptyStatePhase: Equatable, Sendable {
  /// Normal business UI — overlay hidden (`fk_hideEmptyState` or `phase == .content`).
  case content
  /// Spinner + optional copy (initial load). Prefer hiding this while pull-to-refresh runs (`skipsLoadingWhileRefreshing`).
  case loading
  /// Empty list / no search hits — image + copy + optional primary button.
  case empty
  /// Request or transport failure — image + copy + **required** retry (enforced in `FKEmptyStateView`).
  case error
}
