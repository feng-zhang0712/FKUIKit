//
// FKListStateDrivers.swift
// FKUIKit — List state
//
// Protocol-driven UI hooks so ``FKListStateManager`` stays decoupled from concrete scroll views.
//

import UIKit
import FKUIKit

// MARK: - Skeleton

/// Controls a skeleton host such as ``FKSkeletonContainerView``.
@MainActor
public protocol FKListSkeletonDriving: AnyObject {
  func fk_list_setSkeletonActive(_ active: Bool, animated: Bool)
}

extension FKSkeletonContainerView: FKListSkeletonDriving {
  public func fk_list_setSkeletonActive(_ active: Bool, animated: Bool) {
    if active {
      showSkeleton(animated: animated)
    } else {
      hideSkeleton(animated: animated)
    }
  }
}

// MARK: - Primary list surface

/// Shows or hides the main list container (table, collection, stack, etc.).
@MainActor
public protocol FKListPrimarySurfaceDriving: AnyObject {
  func fk_list_setPrimarySurfaceHidden(_ hidden: Bool, animated: Bool)
}

extension UIView: FKListPrimarySurfaceDriving {
  public func fk_list_setPrimarySurfaceHidden(_ hidden: Bool, animated: Bool) {
    let apply = {
      self.isHidden = hidden
      self.alpha = hidden ? 0 : 1
      self.isUserInteractionEnabled = !hidden
    }
    if animated {
      UIView.transition(with: self, duration: 0.2, options: [.beginFromCurrentState, .allowUserInteraction], animations: apply)
    } else {
      apply()
    }
  }
}

// MARK: - Empty / error overlay

/// Hosts ``FKEmptyState`` overlays (typically a `UIViewController.view` or the scroll view itself).
@MainActor
public protocol FKListEmptyStateDriving: AnyObject {
  func fk_list_applyEmptyState(_ model: FKEmptyStateModel, animated: Bool, actionHandler: FKVoidHandler?)
  func fk_list_hideEmptyState(animated: Bool)
}

extension UIView: FKListEmptyStateDriving {
  public func fk_list_applyEmptyState(_ model: FKEmptyStateModel, animated: Bool, actionHandler: FKVoidHandler?) {
    fk_applyEmptyState(model, animated: animated, actionHandler: actionHandler)
  }

  public func fk_list_hideEmptyState(animated: Bool) {
    fk_hideEmptyState(animated: animated)
  }
}

// MARK: - Refresh

/// Finishes header/footer refresh work without hard-coding ``FKRefreshControl`` call sites in the manager.
@MainActor
public protocol FKListRefreshDriving: AnyObject {
  /// Collapses the header after a successful refresh (no-op when not attached / idle).
  func fk_list_endPullToRefreshSuccess()
  /// Collapses the header when the first page is empty.
  func fk_list_endPullToRefreshEmptyList()
  /// Collapses the header after a transport / server failure.
  func fk_list_endPullToRefreshFailure()
  func fk_list_finishLoadMoreSuccess(hasMorePages: Bool)
  func fk_list_finishLoadMoreFailure()
}

/// Bridges ``UIScrollView`` FKRefresh attachments to ``FKListRefreshDriving``.
@MainActor
public final class FKListScrollViewRefreshDriver: FKListRefreshDriving {

  public weak var scrollView: UIScrollView?

  public init(scrollView: UIScrollView) {
    self.scrollView = scrollView
  }

  public func fk_list_endPullToRefreshSuccess() {
    scrollView?.fk_pullToRefresh?.endRefreshing()
  }

  public func fk_list_endPullToRefreshEmptyList() {
    scrollView?.fk_pullToRefresh?.endRefreshingWithEmptyList()
  }

  public func fk_list_endPullToRefreshFailure() {
    scrollView?.fk_pullToRefresh?.endRefreshingWithError(nil)
  }

  public func fk_list_finishLoadMoreSuccess(hasMorePages: Bool) {
    guard let footer = scrollView?.fk_loadMore else { return }
    if hasMorePages {
      footer.endLoadingMore()
    } else {
      footer.endRefreshingWithNoMoreData()
    }
  }

  public func fk_list_finishLoadMoreFailure() {
    scrollView?.fk_loadMore?.endRefreshingWithError(nil)
  }
}

// MARK: - Driver bundle

/// Weak references to optional UI collaborators; pass only the pieces your screen supports.
@MainActor
public struct FKListStateUIDrivers {
  public weak var emptyStateHost: (any FKListEmptyStateDriving)?
  public weak var skeleton: (any FKListSkeletonDriving)?
  public weak var primarySurface: (any FKListPrimarySurfaceDriving)?
  public weak var refresh: (any FKListRefreshDriving)?

  public init(
    emptyStateHost: (any FKListEmptyStateDriving)? = nil,
    skeleton: (any FKListSkeletonDriving)? = nil,
    primarySurface: (any FKListPrimarySurfaceDriving)? = nil,
    refresh: (any FKListRefreshDriving)? = nil
  ) {
    self.emptyStateHost = emptyStateHost
    self.skeleton = skeleton
    self.primarySurface = primarySurface
    self.refresh = refresh
  }
}
