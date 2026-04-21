//
// FKRefreshState.swift
// FKUIKit — FKRefresh
//
// Shared state machine for header and footer; `.refreshing` means in-flight work for both kinds.
//

import Foundation

/// The state machine for a refresh / load-more control.
///
/// Naming note: ``FKRefreshState/refreshing`` is used for **both** pull-to-refresh and load-more
/// “in-flight” work so a single control implementation can stay small. Use ``FKRefreshControl/kind``
/// to interpret UI copy.
public enum FKRefreshState: Equatable {
  /// Inactive; user is not interacting.
  case idle
  /// Pull gesture in progress; `progress` is normalized to `[0, 1]` at the trigger threshold.
  case pulling(progress: CGFloat)
  /// Threshold crossed; release will start refresh (header only — footer skips this state).
  case triggered
  /// Work is running (network / DB). Duplicate triggers are ignored while here.
  case refreshing
  /// Pull-to-refresh finished successfully with data.
  case finished
  /// Pull-to-refresh finished successfully but the first page is empty (distinct copy / analytics).
  case listEmpty
  /// Footer: pagination reached the end.
  case noMoreData
  /// Any failure; optional `Error` is for logging — equality ignores payload.
  case failed(Error?)

  public static func == (lhs: FKRefreshState, rhs: FKRefreshState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle),
         (.triggered, .triggered),
         (.refreshing, .refreshing),
         (.finished, .finished),
         (.listEmpty, .listEmpty),
         (.noMoreData, .noMoreData):
      return true
    case let (.pulling(a), .pulling(b)):
      return a == b
    case (.failed, .failed):
      return true
    default:
      return false
    }
  }
}
