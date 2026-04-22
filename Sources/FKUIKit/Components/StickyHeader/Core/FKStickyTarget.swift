import UIKit

/// A sticky candidate registered into ``FKStickyEngine``.
public struct FKStickyTarget {
  /// Stable identity for diffing and updates.
  public let id: String

  /// Returns current target view each update tick.
  ///
  /// Keep this closure lightweight because it runs during scroll callbacks.
  public let viewProvider: () -> UIView?

  /// Absolute threshold in scroll content coordinates.
  ///
  /// Sticky is activated when `contentOffset.y + topInset >= threshold + activationOffset`.
  public var threshold: CGFloat

  /// Extra activation offset used for delayed or early sticky transition.
  public var activationOffset: CGFloat

  /// If set, sticky position uses this value instead of inherited top inset.
  public var fixedTopInset: CGFloat?

  /// Controls whether this target participates in sticky calculation.
  public var isEnabled: Bool

  /// Optional style switch callback.
  public var onStyleChanged: ((_ style: FKStickyStyle, _ view: UIView) -> Void)?

  /// Optional transition callback with curve-applied progress in `[0, 1]`.
  public var onTransition: ((_ progress: CGFloat, _ view: UIView) -> Void)?

  /// Optional sticky phase callback.
  public var onStateChanged: ((_ state: FKStickyState) -> Void)?

  /// Creates a sticky target.
  ///
  /// - Parameters:
  ///   - id: Stable unique identifier.
  ///   - viewProvider: Closure returning actual view.
  ///   - threshold: Sticky threshold in content coordinates.
  ///   - activationOffset: Extra transition offset.
  ///   - fixedTopInset: Optional target-specific top inset override.
  ///   - isEnabled: Whether sticky calculation is active.
  ///   - onStyleChanged: Style callback.
  ///   - onTransition: Transition progress callback.
  ///   - onStateChanged: State callback.
  public init(
    id: String,
    viewProvider: @escaping () -> UIView?,
    threshold: CGFloat,
    activationOffset: CGFloat = 0,
    fixedTopInset: CGFloat? = nil,
    isEnabled: Bool = true,
    onStyleChanged: ((_ style: FKStickyStyle, _ view: UIView) -> Void)? = nil,
    onTransition: ((_ progress: CGFloat, _ view: UIView) -> Void)? = nil,
    onStateChanged: ((_ state: FKStickyState) -> Void)? = nil
  ) {
    self.id = id
    self.viewProvider = viewProvider
    self.threshold = threshold
    self.activationOffset = activationOffset
    self.fixedTopInset = fixedTopInset
    self.isEnabled = isEnabled
    self.onStyleChanged = onStyleChanged
    self.onTransition = onTransition
    self.onStateChanged = onStateChanged
  }
}

/// Sticky lifecycle events.
public enum FKStickyState {
  /// Before target enters sticky state.
  case willSticky(id: String)
  /// Target entered sticky state.
  case didSticky(id: String)
  /// Target returned to normal state.
  case didUnsticky(id: String)
}
