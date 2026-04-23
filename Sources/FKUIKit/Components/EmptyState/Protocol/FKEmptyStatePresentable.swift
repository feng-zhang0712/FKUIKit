import UIKit

/// Contract for objects that can present or hide `FKEmptyState` overlays.
///
/// This protocol makes presentation testable and decouples feature code from concrete view types.
/// For UIKit screens, `UIView` already conforms via an extension.
@MainActor
public protocol FKEmptyStatePresentable: AnyObject {
  /// Presents an empty-state model.
  ///
  /// - Parameters:
  ///   - model: The view configuration to show. Passing `phase == .content` should hide the overlay.
  ///   - animated: Whether to animate the show/hide transition (respects Reduce Motion).
  ///   - actionHandler: Called when an action button is tapped; use `action.id` for routing.
  ///   - viewTapHandler: Called when the user taps the background area.
  func fk_presentEmptyState(
    _ model: FKEmptyStateModel,
    animated: Bool,
    actionHandler: ((FKEmptyStateAction) -> Void)?,
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
    actionHandler: ((FKEmptyStateAction) -> Void)?,
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
