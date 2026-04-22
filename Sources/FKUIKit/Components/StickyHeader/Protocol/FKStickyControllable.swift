import UIKit

/// Public operations exposed by a sticky engine.
public protocol FKStickyControllable: AnyObject {
  /// Applies configuration and re-evaluates sticky layout.
  func apply(configuration: FKStickyConfiguration)

  /// Replaces all sticky targets.
  func setTargets(_ targets: [FKStickyTarget])

  /// Appends one target.
  func addTarget(_ target: FKStickyTarget)

  /// Removes a target by identifier.
  func removeTarget(withID id: String)

  /// Updates enabled state for a target.
  func setTargetEnabled(_ isEnabled: Bool, forID id: String)

  /// Forces one target to sticky state and disables others.
  func setActiveStickyTarget(withID id: String?)

  /// Enables or disables sticky engine.
  func setEnabled(_ isEnabled: Bool)

  /// Recomputes sticky positions using current scroll offset.
  func reloadLayout()

  /// Clears sticky transforms and states.
  func resetStickyState()
}
