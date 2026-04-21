//
// FKLoadingAnimatorManager.swift
//

import UIKit

/// Global default manager for one-line loading animator calls.
@MainActor
public final class FKLoadingAnimatorManager {
  /// Shared singleton instance.
  public static let shared = FKLoadingAnimatorManager()

  /// App-wide template configuration used by convenience APIs.
  public var templateConfiguration: FKLoadingAnimatorConfiguration {
    get { FKLoadingAnimatorGlobalDefaults.configuration }
    set { FKLoadingAnimatorGlobalDefaults.configuration = newValue }
  }

  /// Creates the singleton manager.
  private init() {}

  /// Mutates the global template configuration in-place.
  ///
  /// - Parameter mutate: Closure receiving a mutable configuration copy.
  public func configureTemplate(_ mutate: (inout FKLoadingAnimatorConfiguration) -> Void) {
    var copy = templateConfiguration
    mutate(&copy)
    templateConfiguration = copy
  }
}
