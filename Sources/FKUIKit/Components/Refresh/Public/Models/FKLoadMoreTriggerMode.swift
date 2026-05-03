import Foundation

/// Defines how a load-more footer decides when to start loading.
public enum FKLoadMoreTriggerMode: Sendable {
  /// Fires when the user scrolls within the configured preload distance of the bottom.
  case automatic
  /// Never fires from scrolling; use ``UIScrollView/fk_beginLoadMore()`` or ``FKRefreshControl/beginLoadingMore(triggerSource:)``.
  case manual
}
