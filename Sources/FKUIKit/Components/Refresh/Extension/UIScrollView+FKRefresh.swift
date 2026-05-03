import UIKit
import ObjectiveC.runtime

// One-line attachment for `FKRefreshControl` on scroll views; at most one header + one footer per view.
// Pair policy: `fk_refreshPolicy`. Re-attaching replaces the previous control.

private enum FKRefreshKeys {
  nonisolated(unsafe) static var pullToRefresh: UInt8 = 0
  nonisolated(unsafe) static var loadMore: UInt8 = 0
  nonisolated(unsafe) static var coordinator: UInt8 = 0
}

public extension UIScrollView {
  /// Concurrency, queueing, and auto-fill rules for the header + footer pair on this scroll view.
  var fk_refreshPolicy: FKRefreshPolicy {
    get { fk_refreshCoordinator.policy }
    set { fk_refreshCoordinator.policy = newValue }
  }

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

  /// Attaches pull-to-refresh with context callback that includes race-safe token metadata.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh
    )
    control.contextActionHandler = action
    fk_setPullToRefresh(control)
    return control
  }

  /// Attaches a pull-to-refresh control with an async callback.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      asyncAction: asyncAction
    )
    fk_setPullToRefresh(control)
    return control
  }

  /// Attaches pull-to-refresh with context async callback (token-safe completion with `async`/`await`).
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh
    )
    control.contextAsyncActionHandler = contextAsyncAction
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

  /// Attaches pull-to-refresh with custom indicator and context callback.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      contentView: contentView
    )
    control.contextActionHandler = action
    fk_setPullToRefresh(control)
    return control
  }

  /// Attaches a pull-to-refresh control with a custom content view and async callback.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      contentView: contentView,
      asyncAction: asyncAction
    )
    fk_setPullToRefresh(control)
    return control
  }

  /// Attaches pull-to-refresh with custom indicator and context async callback.
  @discardableResult
  func fk_addPullToRefresh(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .pullToRefresh,
      configuration: configuration ?? FKRefreshSettings.pullToRefresh,
      contentView: contentView
    )
    control.contextAsyncActionHandler = contextAsyncAction
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

  /// Attaches load-more with context callback that includes race-safe token metadata.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore
    )
    control.contextActionHandler = action
    fk_setLoadMore(control)
    return control
  }

  /// Attaches a load-more control with an async callback.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      asyncAction: asyncAction
    )
    fk_setLoadMore(control)
    return control
  }

  /// Attaches load-more with context async callback (token-safe completion with `async`/`await`).
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore
    )
    control.contextAsyncActionHandler = contextAsyncAction
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

  /// Attaches load-more with custom indicator and context callback.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    action: @escaping FKRefreshActionHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      contentView: contentView
    )
    control.contextActionHandler = action
    fk_setLoadMore(control)
    return control
  }

  /// Attaches a load-more control with a custom content view and async callback.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    asyncAction: @escaping FKRefreshAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      contentView: contentView,
      asyncAction: asyncAction
    )
    fk_setLoadMore(control)
    return control
  }

  /// Attaches load-more with custom indicator and context async callback.
  @discardableResult
  func fk_addLoadMore(
    configuration: FKRefreshConfiguration? = nil,
    contentView: FKRefreshContentView,
    contextAsyncAction: @escaping FKRefreshContextAsyncHandler
  ) -> FKRefreshControl {
    let control = FKRefreshControl(
      kind: .loadMore,
      configuration: configuration ?? FKRefreshSettings.loadMore,
      contentView: contentView
    )
    control.contextAsyncActionHandler = contextAsyncAction
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

  /// Controls footer visibility without removing the load-more control.
  func fk_setLoadMoreHidden(_ isHidden: Bool) {
    fk_loadMore?.isHidden = isHidden
    fk_loadMore?.isUserInteractionEnabled = !isHidden
  }

  /// Clears `.noMoreData` / `.failed` and returns footer to `.idle`.
  func fk_resetLoadMoreState() {
    fk_loadMore?.resetToIdle()
  }

  // MARK: Companion coordination

  /// Resets the footer after a pull-to-refresh begins so pagination can restart from page 1.
  /// Called automatically by the header control — exposed for advanced custom controls.
  func fk_resetLoadMoreAfterPullToRefresh() {
    fk_loadMore?.resetFooterAfterPullToRefresh()
  }

  /// Removes both pull-to-refresh and load-more controls in one call.
  func fk_removeRefreshComponents() {
    fk_removePullToRefresh()
    fk_removeLoadMore()
  }

  // MARK: - Private helpers

  private func fk_setPullToRefresh(_ control: FKRefreshControl) {
    fk_removePullToRefresh()
    objc_setAssociatedObject(self, &FKRefreshKeys.pullToRefresh, control, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    control.setCoordinator(fk_refreshCoordinator)
    control.attach(to: self)
  }

  private func fk_setLoadMore(_ control: FKRefreshControl) {
    fk_removeLoadMore()
    objc_setAssociatedObject(self, &FKRefreshKeys.loadMore, control, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    control.setCoordinator(fk_refreshCoordinator)
    control.attach(to: self)
  }

  private var fk_refreshCoordinator: FKRefreshCoordinator {
    if let coordinator = objc_getAssociatedObject(self, &FKRefreshKeys.coordinator) as? FKRefreshCoordinator {
      return coordinator
    }
    let coordinator = FKRefreshCoordinator()
    coordinator.register(scrollView: self)
    coordinator.policy = FKRefreshSettings.policy
    objc_setAssociatedObject(self, &FKRefreshKeys.coordinator, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return coordinator
  }
}
