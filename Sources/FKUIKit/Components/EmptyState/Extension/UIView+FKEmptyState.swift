//
// UIView+FKEmptyState.swift
//
// Hosts `FKEmptyStateView` on any container (typically `UIViewController.view`) or `UIScrollView`
// without using `UITableView.backgroundView` (avoids z-order issues with refresh controls).
//
// - Note: `fk_applyEmptyState` is declared only on `UIView`; `UIScrollView` inherits it (no duplicate in a subclass extension).
//

import ObjectiveC.runtime
import UIKit

// MARK: - Associated objects

/// Keys for objc associated objects backing the overlay and last model.
enum FKEmptyStateHostKeys {
  nonisolated(unsafe) static var view: UInt8 = 0
  nonisolated(unsafe) static var model: UInt8 = 0
}

/// Box type so the last-applied `FKEmptyStateModel` can be stored in associated objects.
final class FKEmptyStateModelBox {
  let model: FKEmptyStateModel
  init(_ model: FKEmptyStateModel) { self.model = model }
}

// MARK: - UIView

public extension UIView {
  /// The overlay installed by `fk_applyEmptyState`; `nil` until the first presentation.
  var fk_emptyStateView: FKEmptyStateView? {
    objc_getAssociatedObject(self, &FKEmptyStateHostKeys.view) as? FKEmptyStateView
  }

  /// Last model stored for helpers such as `fk_refreshEmptyStateAutomatically` (`UIScrollView`); `nil` if never applied.
  var fk_emptyStateModel: FKEmptyStateModel? {
    (objc_getAssociatedObject(self, &FKEmptyStateHostKeys.model) as? FKEmptyStateModelBox)?.model
  }

  /// Applies or hides the empty-state overlay from `model`.
  ///
  /// - When `model.phase == .content`, hides the overlay (same as `fk_hideEmptyState`).
  /// - On `UIScrollView`, if `phase == .loading` and `skipsLoadingWhileRefreshing` is `true` while `refreshControl?.isRefreshing`, skips showing the loading overlay.
  /// - Creates the `FKEmptyStateView` once; subsequent calls update `isHidden` / `alpha` only.
  ///
  /// - Parameters:
  ///   - model: Visual and behavioral configuration.
  ///   - animated: Fade-in when showing; fade-out is handled by `fk_hideEmptyState`.
  ///   - actionHandler: Invoked when the primary button is tapped; use `[weak self]` to avoid retain cycles.
  func fk_applyEmptyState(
    _ model: FKEmptyStateModel,
    animated: Bool = true,
    actionHandler: FKVoidHandler? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    fk_emptyStateAssertMainThread()
    objc_setAssociatedObject(self, &FKEmptyStateHostKeys.model, FKEmptyStateModelBox(model), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    if model.phase == .content {
      fk_hideEmptyState(animated: animated)
      return
    }

    if fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: self, model: model) {
      if fk_emptyStateView != nil {
        fk_hideEmptyState(animated: animated)
      }
      return
    }

    let view = fk_ensureEmptyStateView()
    view.actionHandler = actionHandler
    view.viewTapHandler = viewTapHandler
    view.apply(model, animated: false)

    let display = {
      view.isHidden = false
      view.alpha = 1
    }
    if animated {
      view.alpha = 0
      view.isHidden = false
      UIView.animate(withDuration: model.fadeDuration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: display)
    } else {
      display()
    }

    fk_emptyStateApplyScrollInteraction(host: self, model: model)
    bringSubviewToFront(view)
  }

  /// Applies the global template with a specific phase in one line.
  ///
  /// Use this API when you only need to toggle `loading/empty/error/content` quickly.
  func fk_setEmptyState(
    phase: FKEmptyStatePhase,
    animated: Bool = true,
    actionHandler: FKVoidHandler? = nil,
    viewTapHandler: FKVoidHandler? = nil
  ) {
    var model = FKEmptyStateManager.shared.templateModel
    model.phase = phase
    fk_applyEmptyState(
      model,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Applies the global template and lets the caller mutate a screen-local model copy.
  func fk_setEmptyState(
    animated: Bool = true,
    actionHandler: FKVoidHandler? = nil,
    viewTapHandler: FKVoidHandler? = nil,
    configure: (inout FKEmptyStateModel) -> Void
  ) {
    var model = FKEmptyStateManager.shared.templateModel
    configure(&model)
    fk_applyEmptyState(
      model,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  /// Hides the empty-state overlay and restores `UIScrollView.isScrollEnabled` when the receiver is a scroll view.
  func fk_hideEmptyState(animated: Bool = true) {
    fk_emptyStateAssertMainThread()
    guard let view = fk_emptyStateView else { return }
    let duration = fk_emptyStateModel?.fadeDuration ?? 0.25
    let hideBlock = { view.alpha = 0 }
    let completion: (Bool) -> Void = { _ in
      view.isHidden = true
      if let scroll = self as? UIScrollView {
        scroll.isScrollEnabled = true
      }
    }
    if animated {
      UIView.animate(withDuration: duration, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: hideBlock, completion: completion)
    } else {
      hideBlock()
      completion(true)
    }
  }

  // MARK: Private

  /// Lazily creates `fk_emptyStateView`, pinned to `frameLayoutGuide` for `UIScrollView`, else to bounds.
  private func fk_ensureEmptyStateView() -> FKEmptyStateView {
    if let existing = fk_emptyStateView {
      return existing
    }
    let view = FKEmptyStateView()
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    if let scroll = self as? UIScrollView {
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: scroll.frameLayoutGuide.topAnchor),
        view.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor),
        view.bottomAnchor.constraint(equalTo: scroll.frameLayoutGuide.bottomAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: topAnchor),
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
    objc_setAssociatedObject(self, &FKEmptyStateHostKeys.view, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return view
  }
}

// MARK: - Shared helpers

/// Returns `true` when a loading overlay should be suppressed because pull-to-refresh is active.
func fk_emptyStateShouldSkipLoadingBecauseOfRefresh(host: UIView, model: FKEmptyStateModel) -> Bool {
  guard let scroll = host as? UIScrollView else { return false }
  guard model.phase == .loading, model.skipsLoadingWhileRefreshing else { return false }
  return scroll.refreshControl?.isRefreshing == true
}

/// Applies `keepScrollEnabled` to `host` when it is a `UIScrollView`.
func fk_emptyStateApplyScrollInteraction(host: UIView, model: FKEmptyStateModel) {
  guard let scroll = host as? UIScrollView else { return }
  scroll.isScrollEnabled = model.keepScrollEnabled
}
