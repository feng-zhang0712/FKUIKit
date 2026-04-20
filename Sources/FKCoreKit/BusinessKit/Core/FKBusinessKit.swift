import Foundation
import UIKit

/// Main entry point for high-frequency business capabilities.
///
/// FKBusinessKit is designed to be:
/// - Pure Swift (Swift 5.9+), iOS 13+
/// - No third-party dependencies
/// - Thread-safe and non-blocking
/// - Easy to plug into any architecture (MVVM/MVP/etc.)
public final class FKBusinessKit: @unchecked Sendable {
  /// Shared singleton instance.
  public static let shared = FKBusinessKit()

  /// Internal configuration storage used to avoid capturing `self` during initialization.
  private let configurationStore: FKBusinessConfigurationStoring

  /// Current runtime configuration.
  ///
  /// Updates are thread-safe.
  public var configuration: FKBusinessKitConfiguration {
    get { configurationStore.configuration }
    set { configurationStore.configuration = newValue }
  }

  /// App version and update management.
  public let version: FKBusinessVersioning

  /// Global analytics and event tracking.
  public let track: FKBusinessTracking

  /// In-app localization that does not depend on system language.
  public let i18n: FKBusinessLocalizing

  /// Unified, non-invasive application lifecycle observation.
  public let lifecycle: FKBusinessLifecycleObserving

  /// Deeplink and Universal Link routing.
  public let deeplink: FKBusinessDeeplinkRouting

  /// Device and application information.
  public let info: FKBusinessInfoProviding

  /// Common business utilities.
  public let utils: FKBusinessUtilitiesProviding

  /// Creates the kit with custom collaborators.
  ///
  /// - Parameters:
  ///   - configuration: Initial global configuration.
  ///   - version: Optional custom version manager implementation.
  ///   - track: Optional custom analytics tracker implementation.
  ///   - i18n: Optional custom localization manager implementation.
  ///   - lifecycle: Optional custom lifecycle observer implementation.
  ///   - deeplink: Optional custom deeplink router implementation.
  ///   - info: Optional custom app/device info provider.
  ///   - utils: Optional custom utilities provider.
  /// - Important: Prefer using ``shared`` for app-wide behavior.
  public init(
    configuration: FKBusinessKitConfiguration = FKBusinessKitConfiguration(),
    version: FKBusinessVersioning? = nil,
    track: FKBusinessTracking? = nil,
    i18n: FKBusinessLocalizing? = nil,
    lifecycle: FKBusinessLifecycleObserving? = nil,
    deeplink: FKBusinessDeeplinkRouting? = nil,
    info: FKBusinessInfoProviding? = nil,
    utils: FKBusinessUtilitiesProviding? = nil
  ) {
    let store = FKBusinessConfigurationStore(initial: configuration)
    configurationStore = store

    let infoProvider = info ?? FKBusinessInfoProvider(configurationProvider: { store.configuration })
    self.info = infoProvider

    let lifecycleObserver = lifecycle ?? FKBusinessLifecycleObserver()
    self.lifecycle = lifecycleObserver

    let i18nManager = i18n ?? FKBusinessI18nManager(defaultLanguageCode: configuration.defaultLanguageCode)
    self.i18n = i18nManager

    let deeplinkRouter = deeplink ?? FKBusinessDeeplinkRouter()
    self.deeplink = deeplinkRouter

    let versionManager = version ?? FKBusinessVersionManager(infoProvider: infoProvider)
    self.version = versionManager

    let trackManager = track ?? FKBusinessAnalyticsTracker(
      configurationProvider: { store.configuration },
      infoProvider: infoProvider
    )
    self.track = trackManager

    let utilities = utils ?? FKBusinessUtilities(
      i18n: i18nManager,
      infoProvider: infoProvider
    )
    self.utils = utilities
  }

  /// Updates the current configuration atomically.
  ///
  /// - Parameter transform: Mutation closure for current configuration.
  public func updateConfiguration(_ transform: (inout FKBusinessKitConfiguration) -> Void) {
    configurationStore.update(transform)
  }
}

/// Internal abstraction for configuration storage.
protocol FKBusinessConfigurationStoring: AnyObject {
  /// Current toolkit configuration.
  var configuration: FKBusinessKitConfiguration { get set }

  /// Mutates current configuration in a thread-safe way.
  ///
  /// - Parameter transform: Mutation closure applied atomically.
  func update(_ transform: (inout FKBusinessKitConfiguration) -> Void)
}

/// Thread-safe configuration store for dependency injection without referencing `self`.
final class FKBusinessConfigurationStore: FKBusinessConfigurationStoring, @unchecked Sendable {
  /// Lock that protects all reads/writes of `_configuration`.
  private let lock = NSLock()

  /// Backing storage for the mutable configuration object.
  private var _configuration: FKBusinessKitConfiguration

  /// Creates a store with an initial configuration value.
  ///
  /// - Parameter initial: Initial configuration.
  init(initial: FKBusinessKitConfiguration) {
    _configuration = initial
  }

  /// Thread-safe configuration accessor.
  var configuration: FKBusinessKitConfiguration {
    get {
      lock.lock()
      let value = _configuration
      lock.unlock()
      return value
    }
    set {
      lock.lock()
      _configuration = newValue
      lock.unlock()
    }
  }

  func update(_ transform: (inout FKBusinessKitConfiguration) -> Void) {
    lock.lock()
    transform(&_configuration)
    lock.unlock()
  }
}

