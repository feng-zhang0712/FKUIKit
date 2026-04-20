//
// FKStarRatingManager.swift
//
// Global default manager for FKStarRating.
//

import UIKit

/// Singleton manager for app-wide `FKStarRating` defaults.
@MainActor
public final class FKStarRatingManager {
  /// Shared singleton instance.
  public static let shared = FKStarRatingManager()

  /// Default configuration applied to new `FKStarRating` instances.
  public var defaultConfiguration = FKStarRatingConfiguration()

  private init() {}

  /// Mutates global default configuration in place.
  public func configureDefault(_ updates: (inout FKStarRatingConfiguration) -> Void) {
    var configuration = defaultConfiguration
    updates(&configuration)
    defaultConfiguration = configuration
  }

  /// Restores global defaults to factory settings.
  public func resetDefault() {
    defaultConfiguration = FKStarRatingConfiguration()
  }
}
