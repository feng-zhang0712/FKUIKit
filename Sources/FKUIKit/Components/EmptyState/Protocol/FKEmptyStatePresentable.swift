//
// FKEmptyStatePresentable.swift
//
// Protocol-oriented empty-state presentation abstraction.
//

import UIKit

/// Contract for objects that can present or hide `FKEmptyState` overlays.
@MainActor
public protocol FKEmptyStatePresentable: AnyObject {
  /// Presents an empty-state model.
  func fk_presentEmptyState(
    _ model: FKEmptyStateModel,
    animated: Bool,
    actionHandler: FKVoidHandler?,
    viewTapHandler: FKVoidHandler?
  )

  /// Hides the empty-state overlay.
  func fk_dismissEmptyState(animated: Bool)
}

@MainActor
extension UIView: FKEmptyStatePresentable {
  public func fk_presentEmptyState(
    _ model: FKEmptyStateModel,
    animated: Bool,
    actionHandler: FKVoidHandler?,
    viewTapHandler: FKVoidHandler?
  ) {
    fk_applyEmptyState(
      model,
      animated: animated,
      actionHandler: actionHandler,
      viewTapHandler: viewTapHandler
    )
  }

  public func fk_dismissEmptyState(animated: Bool) {
    fk_hideEmptyState(animated: animated)
  }
}
