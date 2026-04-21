//
// FKCarouselGlobalDefaults.swift
//

import Foundation

/// Internal global storage for shared carousel configuration.
enum FKCarouselGlobalDefaults {
  /// Shared default configuration template.
  ///
  /// Main-actor isolation guarantees thread-safe mutation for UIKit-facing usage.
  @MainActor static var configuration = FKCarouselConfiguration()
}
