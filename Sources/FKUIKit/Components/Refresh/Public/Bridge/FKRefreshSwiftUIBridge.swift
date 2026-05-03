#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Binds a UIKit scroll view hosted in SwiftUI and installs refresh controls using the same overloads as ``UIScrollView/fk_addPullToRefresh(configuration:action:)`` (sync, async, context sync/async).
///
/// Typical usage:
/// 1. Keep one `@StateObject` / `ObservableObject` bridge.
/// 2. In `UIViewRepresentable`, call `bind(scrollView:)` once the scroll view exists.
/// 3. Call `installPullToRefresh` / `installLoadMore` with the handler style you need.
@MainActor
public final class FKRefreshSwiftUIBridge: ObservableObject {
  private weak var scrollView: UIScrollView?

  public init() {}

  /// Binds the target scroll view. Rebinding automatically detaches from previous view.
  public func bind(scrollView: UIScrollView) {
    if self.scrollView !== scrollView {
      self.scrollView?.fk_removeRefreshComponents()
    }
    self.scrollView = scrollView
  }

  /// Installs pull-to-refresh using context callback to support race-safe completion.
  @discardableResult
  public func installPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addPullToRefresh(configuration: configuration, action: action)
  }

  /// Installs pull-to-refresh with an async handler (optional automatic end via configuration).
  @discardableResult
  public func installPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addPullToRefresh(configuration: configuration, asyncAction: asyncAction)
  }

  /// Installs pull-to-refresh with context async handler for token-aware `async`/`await` flows.
  @discardableResult
  public func installPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addPullToRefresh(configuration: configuration, contextAsyncAction: contextAsyncAction)
  }

  /// Installs load-more using context callback to support race-safe completion.
  @discardableResult
  public func installLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addLoadMore(configuration: configuration, action: action)
  }

  /// Installs load-more with an async handler (optional automatic end via configuration).
  @discardableResult
  public func installLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addLoadMore(configuration: configuration, asyncAction: asyncAction)
  }

  /// Installs load-more with context async handler for token-aware `async`/`await` flows.
  @discardableResult
  public func installLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addLoadMore(configuration: configuration, contextAsyncAction: contextAsyncAction)
  }

  /// Applies pair policy on the bound scroll view.
  public func setPolicy(_ policy: FKRefreshPolicy) {
    scrollView?.fk_refreshPolicy = policy
  }

  /// Programmatically starts pull-to-refresh.
  public func beginPullToRefresh(animated: Bool = true) {
    scrollView?.fk_beginPullToRefresh(animated: animated)
  }

  /// Programmatically starts load-more.
  public func beginLoadMore() {
    scrollView?.fk_beginLoadMore()
  }
}
#endif

