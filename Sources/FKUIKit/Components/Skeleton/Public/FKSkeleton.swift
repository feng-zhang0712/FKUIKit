import UIKit

/// Namespace object owning ``FKSkeleton/defaultConfiguration``.
///
/// Integration surfaces:
/// - Overlay: ``UIView/fk_showSkeleton(configuration:animated:respectsSafeArea:blocksInteraction:)``
/// - Automatic placeholders: ``UIView/fk_showAutoSkeleton(configuration:options:animated:)``
/// - Layout primitives: ``FKSkeletonContainerView``, ``FKSkeletonView``, ``FKSkeletonPresets``
public final class FKSkeleton {

  private static let defaultConfigurationLock = NSLock()
  nonisolated(unsafe) private static var _defaultConfiguration = FKSkeletonConfiguration()

  /// Thread-safe defaults applied whenever a more specific ``FKSkeletonConfiguration`` is unavailable.
  public static var defaultConfiguration: FKSkeletonConfiguration {
    get {
      defaultConfigurationLock.lock()
      defer { defaultConfigurationLock.unlock() }
      return _defaultConfiguration
    }
    set {
      defaultConfigurationLock.lock()
      defer { defaultConfigurationLock.unlock() }
      _defaultConfiguration = newValue
    }
  }

  private init() {}
}
