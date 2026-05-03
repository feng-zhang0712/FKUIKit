//
// FKListStateManager.swift
// FKUIKit — List state
//
// Central coordinator for list placeholders, skeletons, primary surfaces, and FK refresh controls.
//

import UIKit
import FKUIKit

// MARK: - Configuration

/// Customisable empty/error visuals; defaults follow ``FKListEmptyStateConfigurationFactory``.
public struct FKListStateManagerConfiguration {
  public var emptyListModel: () -> FKEmptyStateConfiguration
  public var errorModel: (FKListDisplayedError) -> FKEmptyStateConfiguration
  /// When `true`, ``FKListState/empty`` keeps the primary list surface visible (e.g. overlays disabled).
  public var keepsListVisibleOnEmpty: Bool
  /// When `true`, ``FKListState/error`` keeps the primary list surface visible (toast-only error flows).
  public var keepsListVisibleOnError: Bool
  /// When `false`, ``FKListState/empty`` skips ``FKEmptyState`` presentation (list chrome + refresh still update).
  public var presentsEmptyOverlay: Bool
  /// When `false`, ``FKListState/error`` skips the error overlay (use toast/snackbar at the binding layer).
  public var presentsErrorOverlay: Bool

  public init(
    emptyListModel: @escaping () -> FKEmptyStateConfiguration = { FKListEmptyStateConfigurationFactory.configurationForEmptyList() },
    errorModel: @escaping (FKListDisplayedError) -> FKEmptyStateConfiguration = {
      FKListEmptyStateConfigurationFactory.configurationForDisplayedError($0)
    },
    keepsListVisibleOnEmpty: Bool = false,
    keepsListVisibleOnError: Bool = false,
    presentsEmptyOverlay: Bool = true,
    presentsErrorOverlay: Bool = true
  ) {
    self.emptyListModel = emptyListModel
    self.errorModel = errorModel
    self.keepsListVisibleOnEmpty = keepsListVisibleOnEmpty
    self.keepsListVisibleOnError = keepsListVisibleOnError
    self.presentsEmptyOverlay = presentsEmptyOverlay
    self.presentsErrorOverlay = presentsErrorOverlay
  }
}

// MARK: - Manager

/// Coordinates list placeholders so business code only calls ``setState(_:animated:)``.
@MainActor
public final class FKListStateManager {

  /// Latest resolved state (read on the main thread).
  public private(set) var state: FKListState = .idle

  /// Called on the main thread whenever ``state`` actually changes.
  public var onStateChange: ((_ previous: FKListState, _ new: FKListState) -> Void)?

  /// Primary button on empty / full-screen error overlays.
  public var onOverlayPrimaryAction: FKVoidHandler?

  /// Pull-to-refresh finished successfully but returned zero rows (optional analytics).
  public var onPullToRefreshEndedEmpty: FKVoidHandler?

  public var configuration: FKListStateManagerConfiguration
  public var ui: FKListStateUIDrivers

  public init(
    ui: FKListStateUIDrivers,
    configuration: FKListStateManagerConfiguration = FKListStateManagerConfiguration()
  ) {
    self.ui = ui
    self.configuration = configuration
  }

  /// Thread-safe entry: always hops to the main queue before mutating UI or ``state``.
  public func setState(_ newState: FKListState, animated: Bool = true) {
    if Thread.isMainThread {
      applyStateIfNeeded(newState, animated: animated)
    } else {
      DispatchQueue.main.async { [self] in
        self.applyStateIfNeeded(newState, animated: animated)
      }
    }
  }

  // MARK: - Private

  private func applyStateIfNeeded(_ newState: FKListState, animated: Bool) {
    if newState == state { return }
    let previous = state
    state = newState
    onStateChange?(previous, newState)
    syncUI(from: previous, to: newState, animated: animated)
  }

  private func syncUI(from previous: FKListState, to newState: FKListState, animated: Bool) {
    let host = ui.emptyStateHost
    let skeleton = ui.skeleton
    let surface = ui.primarySurface
    let refresh = ui.refresh

    switch newState {
    case .idle:
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      host?.fk_list_hideEmptyState(animated: animated)
      refresh?.fk_list_endPullToRefreshSuccess()

    case .loading(let kind):
      refresh?.fk_list_endPullToRefreshSuccess()
      switch kind {
      case .initial:
        skeleton?.fk_list_setSkeletonActive(true, animated: animated)
        surface?.fk_list_setPrimarySurfaceHidden(true, animated: animated)
        host?.fk_list_hideEmptyState(animated: animated)
      case .silent:
        skeleton?.fk_list_setSkeletonActive(false, animated: animated)
        surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
        host?.fk_list_hideEmptyState(animated: animated)
      }

    case .refreshing:
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      host?.fk_list_hideEmptyState(animated: animated)

    case .content(let snapshot):
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      host?.fk_list_hideEmptyState(animated: animated)
      refresh?.fk_list_endPullToRefreshSuccess()
      refresh?.fk_list_finishLoadMoreSuccess(hasMorePages: snapshot.hasMorePages)

    case .empty:
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      if configuration.keepsListVisibleOnEmpty {
        surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      } else {
        surface?.fk_list_setPrimarySurfaceHidden(true, animated: animated)
      }
      if configuration.presentsEmptyOverlay {
        let model = configuration.emptyListModel()
        host?.fk_list_applyEmptyState(model, animated: animated, actionHandler: { [weak self] _ in
          self?.onOverlayPrimaryAction?()
        })
      } else {
        host?.fk_list_hideEmptyState(animated: animated)
      }
      refresh?.fk_list_endPullToRefreshEmptyList()
      if case .refreshing = previous {
        onPullToRefreshEndedEmpty?()
      }
      refresh?.fk_list_finishLoadMoreSuccess(hasMorePages: false)

    case .error(let error):
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      if configuration.keepsListVisibleOnError {
        surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      } else {
        surface?.fk_list_setPrimarySurfaceHidden(true, animated: animated)
      }
      if configuration.presentsErrorOverlay {
        let model = configuration.errorModel(error)
        host?.fk_list_applyEmptyState(model, animated: animated, actionHandler: { [weak self] _ in
          self?.onOverlayPrimaryAction?()
        })
      } else {
        host?.fk_list_hideEmptyState(animated: animated)
      }
      refresh?.fk_list_endPullToRefreshFailure()

    case .loadMoreFailed(_):
      skeleton?.fk_list_setSkeletonActive(false, animated: animated)
      surface?.fk_list_setPrimarySurfaceHidden(false, animated: animated)
      host?.fk_list_hideEmptyState(animated: animated)
      refresh?.fk_list_endPullToRefreshFailure()
      refresh?.fk_list_finishLoadMoreFailure()
    }
  }
}
