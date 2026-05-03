import UIKit

/// Global appearance defaults for FKRefresh.
public enum FKRefreshSettings {

  /// Default used by `fk_addPullToRefresh` when `configuration` is `nil`.
  ///
  /// This is stored as a process-wide mutable global. For consistency, set it once at app launch
  /// (or mutate on the main actor) before attaching refresh controls from multiple threads.
  public nonisolated(unsafe) static var pullToRefresh: FKRefreshConfiguration = .default

  /// Default used by `fk_addLoadMore` when `configuration` is `nil`.
  ///
  /// This is stored as a process-wide mutable global. For consistency, set it once at app launch
  /// (or mutate on the main actor) before attaching refresh controls from multiple threads.
  public nonisolated(unsafe) static var loadMore: FKRefreshConfiguration = .default

  /// Default policy applied to newly attached refresh pairs.
  ///
  /// This is stored as a process-wide mutable global. For consistency, set it once at app launch
  /// (or mutate on the main actor) before attaching refresh controls from multiple threads.
  public nonisolated(unsafe) static var policy: FKRefreshPolicy = .default
}
