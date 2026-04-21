import Foundation

/// Abstract contract for badge presentation APIs.
///
/// The protocol enables decoupling UI modules from a specific badge implementation.
@MainActor
public protocol FKBadgePresenting: AnyObject {
  /// Displays a pure dot badge.
  ///
  /// - Parameters:
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  func showDot(animated: Bool, animation: FKBadgeAnimation)
  /// Displays a numeric badge.
  ///
  /// - Parameters:
  ///   - count: Numeric value to display.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  func showCount(_ count: Int, animated: Bool, animation: FKBadgeAnimation)
  /// Displays a text badge.
  ///
  /// - Parameters:
  ///   - text: Badge text value.
  ///   - animated: Whether to animate visibility transition.
  ///   - animation: Optional emphasis animation.
  func showText(_ text: String, animated: Bool, animation: FKBadgeAnimation)
  /// Clears content and hides the badge.
  ///
  /// - Parameter animated: Whether hide transition should animate.
  func clear(animated: Bool)
}

@MainActor
extension FKBadgeController: FKBadgePresenting {}
