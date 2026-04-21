//
// FKLoadingAnimatorGlobalDefaults.swift
//

import Foundation

/// Internal storage for module-wide default configuration.
///
/// This type is intentionally scoped to the module to avoid accidental external mutation.
enum FKLoadingAnimatorGlobalDefaults {
  /// Global template configuration used by convenience APIs.
  ///
  /// Access is constrained to the main actor because consumers are UIKit-facing.
  @MainActor static var configuration = FKLoadingAnimatorConfiguration()
}
