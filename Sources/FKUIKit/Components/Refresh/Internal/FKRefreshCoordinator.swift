import UIKit

/// Coordinates one header + one footer on the same scroll view (concurrency, queued triggers, auto-fill).
@MainActor
internal final class FKRefreshCoordinator {
  weak var scrollView: UIScrollView?
  weak var pullControl: FKRefreshControl?
  weak var loadMoreControl: FKRefreshControl?

  var policy: FKRefreshPolicy = .default

  private var runningKinds: Set<FKRefreshKind> = []
  private var queuedKind: FKRefreshKind?
  private var autoFillTriggerCount = 0

  func register(scrollView: UIScrollView) {
    self.scrollView = scrollView
  }

  func register(control: FKRefreshControl) {
    switch control.kind {
    case .pullToRefresh:
      pullControl = control
    case .loadMore:
      loadMoreControl = control
    }
  }

  func unregister(control: FKRefreshControl) {
    switch control.kind {
    case .pullToRefresh:
      if pullControl === control { pullControl = nil }
    case .loadMore:
      if loadMoreControl === control { loadMoreControl = nil }
    }
    runningKinds.remove(control.kind)
    if queuedKind == control.kind {
      queuedKind = nil
    }
  }

  func canStart(kind: FKRefreshKind) -> Bool {
    switch policy.concurrency {
    case .parallel:
      return true
    case .mutuallyExclusive:
      return runningKinds.isEmpty
    case .queueing:
      if runningKinds.isEmpty { return true }
      queuedKind = kind
      return false
    }
  }

  func didStart(kind: FKRefreshKind) {
    runningKinds.insert(kind)
    if kind == .pullToRefresh {
      autoFillTriggerCount = 0
    }
  }

  func didComplete(kind: FKRefreshKind, isTerminal: Bool) {
    if isTerminal {
      runningKinds.remove(kind)
      triggerQueuedIfNeeded()
    }
    evaluateAutoFillIfNeeded()
  }

  func didCancel(kind: FKRefreshKind) {
    runningKinds.remove(kind)
    triggerQueuedIfNeeded()
  }

  private func triggerQueuedIfNeeded() {
    guard runningKinds.isEmpty else { return }
    guard let queued = queuedKind else { return }
    queuedKind = nil
    switch queued {
    case .pullToRefresh:
      pullControl?.beginRefreshing(animated: true, triggerSource: .automated)
    case .loadMore:
      loadMoreControl?.beginLoadingMore(triggerSource: .automated)
    }
  }

  private func evaluateAutoFillIfNeeded() {
    guard policy.autoFill.isEnabled else { return }
    guard autoFillTriggerCount < policy.autoFill.maxTriggerCount else { return }
    guard runningKinds.isEmpty else { return }
    guard let scrollView, let loadMore = loadMoreControl else { return }
    guard loadMore.isEnabled else { return }
    guard loadMore.state == .idle else { return }
    guard !loadMore.isHidden else { return }

    let visibleH = scrollView.bounds.height
      - scrollView.adjustedContentInset.top
      - scrollView.adjustedContentInset.bottom
    guard visibleH > 0 else { return }

    if scrollView.contentSize.height <= visibleH + 0.5 {
      autoFillTriggerCount += 1
      loadMore.beginLoadingMore(triggerSource: .automated)
    }
  }
}

