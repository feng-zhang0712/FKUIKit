//
// FKCarouselManager.swift
//

import Foundation

/// Shared manager used to provide app-wide default configuration.
///
/// Use this manager to define a global style baseline that all newly created carousel
/// instances can inherit, while still allowing per-instance overrides.
@MainActor
public final class FKCarouselManager {
  /// Shared singleton.
  public static let shared = FKCarouselManager()

  /// Global template configuration used by convenience APIs.
  ///
  /// Updating this value affects only future reads; existing carousel instances keep
  /// their currently applied configuration until `apply(configuration:)` is called again.
  public var templateConfiguration: FKCarouselConfiguration {
    get { FKCarouselGlobalDefaults.configuration }
    set { FKCarouselGlobalDefaults.configuration = newValue }
  }

  /// Prevents external instantiation and enforces singleton usage.
  private init() {}
}
