import ObjectiveC.runtime
import UIKit

// MARK: - UIScrollView

public extension UIScrollView {
  /// Convenience alias for `fk_applyEmptyState` (historical name).
  ///
  /// - Note: This method exists for API readability in scroll-heavy screens. Internally it calls
  ///   `UIView.fk_applyEmptyState` (inherited by `UIScrollView`).
  func fk_showEmptyState(
    _ model: FKEmptyStateModel,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_applyEmptyState(
      model,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Updates the existing overlay’s content without tearing down the view (no-op if never shown).
  ///
  /// Retains the latest model in associated storage and respects refresh-control skipping for loading phases.
  ///
  /// Performance notes:
  /// - Updating avoids tearing down Auto Layout constraints and reduces animation jank.
  /// - Prefer this method when you want to change copy/spinner while keeping the overlay visible.
  func fk_updateEmptyState(_ model: FKEmptyStateModel, animated: Bool = true) {
    fk_emptyStateAssertMainThread()
    objc_setAssociatedObject(
      self,
      &FKEmptyStateHostKeys.model,
      FKEmptyStateModelBox(model),
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )

    if model.phase == .content {
      fk_hideEmptyState(animated: animated)
      return
    }

    if fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: self, model: model) {
      fk_hideEmptyState(animated: animated)
      return
    }

    guard let view = fk_emptyStateView else { return }
    view.apply(model, animated: animated)
    fk_emptyStateApplyScrollInteraction(host: self, model: model)
    bringSubviewToFront(view)
  }

  /// When `isEmpty` is false, forces `phase = .content` before applying (hides overlay).
  ///
  /// - Parameter isEmpty: Pass your list emptiness predicate (e.g. `items.isEmpty`).
  func fk_updateEmptyStateVisibility(
    isEmpty: Bool,
    model: FKEmptyStateModel,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    var resolved = model
    if !isEmpty {
      resolved.phase = .content
    }
    fk_applyEmptyState(
      resolved,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// If `automaticallyShowsWhenContentFits` is enabled on the stored model, shows the empty state when `contentSize` fits in the visible area.
  ///
  /// Call from `scrollViewDidScroll` / `layoutSubviews` when using short content empty states.
  ///
  /// Edge cases:
  /// - Uses `adjustedContentInset` and bounds height; safe area and refresh controls are accounted for.
  /// - Will only run when `fk_emptyStateModel.automaticallyShowsWhenContentFits == true`.
  func fk_refreshEmptyStateAutomatically(
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    guard var model = fk_emptyStateModel, model.automaticallyShowsWhenContentFits else { return }
    let visibleHeight = bounds.height - adjustedContentInset.top - adjustedContentInset.bottom
    let shouldShow = contentSize.height <= max(0, visibleHeight)
    if shouldShow, model.phase == .content {
      model.phase = .empty
    }
    fk_updateEmptyStateVisibility(
      isEmpty: shouldShow,
      model: model,
      animated: true,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Shows the overlay when `itemCount == 0`; otherwise hides it (`phase = .content`).
  ///
  /// If `itemCount == 0` and `model.phase == .content`, coerces phase to `.empty` so something visible is shown.
  ///
  /// - Note: For collection views, prefer `fk_totalItemCount()` to compute `itemCount`.
  func fk_updateEmptyState(
    itemCount: Int,
    model: FKEmptyStateModel,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    if itemCount > 0 {
      var hidden = model
      hidden.phase = .content
      fk_applyEmptyState(
        hidden,
        animated: animated,
        actionHandler: actionHandler,
        viewTapHandler: viewTapHandler
      )
    } else {
      var emptyModel = model
      if emptyModel.phase == .content {
        emptyModel.phase = .empty
      }
      fk_applyEmptyState(
        emptyModel,
        animated: animated,
        actionHandler: actionHandler,
        viewTapHandler: viewTapHandler
      )
    }
  }
}

// MARK: - UITableView

public extension UITableView {
  /// Sums `numberOfRows(inSection:)` across all sections (handy for `fk_updateEmptyState(itemCount:...)`).
  func fk_totalRowCount() -> Int {
    (0..<numberOfSections).reduce(0) { partial, section in
      partial + numberOfRows(inSection: section)
    }
  }

  /// Uses `fk_totalRowCount()` as `itemCount` for `fk_updateEmptyState(itemCount:model:...)`.
  func fk_updateEmptyStateForTable(
    model: FKEmptyStateModel,
    animated: Bool = true,
    actionHandler: ((FKEmptyStateAction) -> Void)? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_updateEmptyState(
      itemCount: fk_totalRowCount(),
      model: model,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }
}

// MARK: - UICollectionView

public extension UICollectionView {
  /// Sums `numberOfItems(inSection:)` across all sections.
  func fk_totalItemCount() -> Int {
    (0..<numberOfSections).reduce(0) { partial, section in
      partial + numberOfItems(inSection: section)
    }
  }
}
