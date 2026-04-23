#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// Bridge object for wiring FKRefresh from SwiftUI wrappers that host a UIKit scroll view.
///
/// Typical usage:
/// 1. Keep one `@StateObject` bridge.
/// 2. In `UIViewRepresentable.makeUIView`, call `bridge.bind(scrollView:)`.
/// 3. Configure handlers with `installPullToRefresh` / `installLoadMore`.
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

  /// Installs load-more using context callback to support race-safe completion.
  @discardableResult
  public func installLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl? {
    guard let scrollView else { return nil }
    return scrollView.fk_addLoadMore(configuration: configuration, action: action)
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

