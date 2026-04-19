//
// UIScrollView+FKRefresh.swift
// FKUIKit — FKRefresh
//
// Associated-object API to attach one header and one footer control per scroll view; merges
// `FKRefreshSettings` when `configuration` is nil.
//

import UIKit
import ObjectiveC.runtime

// MARK: - Associated object keys

private enum FKRefreshKeys {
  nonisolated(unsafe) static var pullToRefresh: UInt8 = 0
  nonisolated(unsafe) static var loadMore: UInt8 = 0
}

// MARK: - UIScrollView extension

public extension UIScrollView {

  // MARK: Pull-to-refresh

  /// Attaches a pull-to-refresh control with the default indicator.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKVoidHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      action: action
    )
    fk_setPullToRefresh(control)
    return control
  }

  /// Attaches a pull-to-refresh control with a custom content view.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    action: @escaping FKVoidHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      contentView: contentView,
      action: action
    )
    fk_setPullToRefresh(control)
    return control
  }

  /// The currently attached pull-to-refresh control, if any.
  var fk_pullToRefresh: FKRefreshControl? {
    objc_getAssociatedObject(self, &FKRefreshKeys.pullToRefresh) as? FKRefreshControl
  }

  /// Removes the pull-to-refresh control.
  func fk_removePullToRefresh() {
    fk_pullToRefresh?.detach()
    objc_setAssociatedObject(self, &FKRefreshKeys.pullToRefresh, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  /// Programmatically starts the header action (respects ``FKRefreshControl/isEnabled``).
  /// Typical use: call once from `viewDidAppear` for an automatic first load.
  func fk_beginPullToRefresh(animated: Bool = true) {
    fk_pullToRefresh?.beginRefreshing(animated: animated)
  }

  // MARK: Load-more

  /// Attaches a load-more control with the default indicator.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKVoidHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      action: action
    )
    fk_setLoadMore(control)
    return control
  }

  /// Attaches a load-more control with a custom content view.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    action: @escaping FKVoidHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      contentView: contentView,
      action: action
    )
    fk_setLoadMore(control)
    return control
  }

  /// The currently attached load-more control, if any.
  var fk_loadMore: FKRefreshControl? {
    objc_getAssociatedObject(self, &FKRefreshKeys.loadMore) as? FKRefreshControl
  }

  /// Removes the load-more control.
  func fk_removeLoadMore() {
    fk_loadMore?.detach()
    objc_setAssociatedObject(self, &FKRefreshKeys.loadMore, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  /// Programmatically starts the footer action.
  func fk_beginLoadMore() {
    fk_loadMore?.beginLoadingMore()
  }

  // MARK: Companion coordination

  /// Resets the footer after a pull-to-refresh begins so pagination can restart from page 1.
  /// Called automatically by the header control — exposed for advanced custom controls.
  func fk_resetLoadMoreAfterPullToRefresh() {
    fk_loadMore?.resetFooterAfterPullToRefresh()
  }

  // MARK: - Private helpers

  private func fk_setPullToRefresh(_ control: FKRefreshControl) {
    fk_removePullToRefresh()
    objc_setAssociatedObject(self, &FKRefreshKeys.pullToRefresh, control, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    control.attach(to: self)
  }

  private func fk_setLoadMore(_ control: FKRefreshControl) {
    fk_removeLoadMore()
    objc_setAssociatedObject(self, &FKRefreshKeys.loadMore, control, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    control.attach(to: self)
  }
}
