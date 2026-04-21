import UIKit

/// Global badge manager for app-wide style and behavior.
///
/// Use `shared` to set baseline defaults once (for example in app launch), while still allowing
/// each `FKBadgeController` to override its own configuration independently.
@MainActor
public final class FKBadgeManager {
  /// Shared singleton manager.
  public static let shared = FKBadgeManager()

  /// Baseline configuration used by newly created badge controllers.
  ///
  /// Existing controllers are not force-overwritten unless they still read global defaults.
  public var defaultConfiguration: FKBadgeConfiguration {
    didSet { FKBadge.defaultConfiguration = defaultConfiguration }
  }

  /// Creates the singleton.
  ///
  /// This initializer is intentionally private to keep global badge policy centralized.
  private init() {
    self.defaultConfiguration = FKBadge.defaultConfiguration
  }

  /// Hides all active badges currently tracked by the registry.
  ///
  /// - Parameter animated: Whether hide transition should animate.
  public func hideAll(animated: Bool = false) {
    FKBadge.hideAllBadges(animated: animated)
  }

  /// Restores visibility behavior for all tracked badges.
  ///
  /// - Parameter animated: Whether restore transition should animate.
  public func restoreAll(animated: Bool = false) {
    FKBadge.restoreAllBadges(animated: animated)
  }
}
