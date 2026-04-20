//
// FKEmptyStateManager.swift
//
// Global configuration entry for FKEmptyState.
//

import UIKit

/// Singleton manager that stores app-wide defaults for `FKEmptyState`.
///
/// Mutate `templateModel` once during app launch, then override per-screen as needed.
/// All APIs are main-thread constrained because UIKit-backed values are involved.
@MainActor
public final class FKEmptyStateManager {
  /// Shared singleton instance.
  public static let shared = FKEmptyStateManager()

  /// App-wide template model used by one-line helper APIs.
  public var templateModel: FKEmptyStateModel {
    get {
      fk_emptyStateAssertMainThread()
      return FKEmptyStateGlobalDefaults.template
    }
    set {
      fk_emptyStateAssertMainThread()
      FKEmptyStateGlobalDefaults.template = newValue
    }
  }

  private init() {
    // Keep init private for singleton semantics.
  }

  /// Replaces the global template using a mutation closure.
  public func configureTemplate(_ configure: (inout FKEmptyStateModel) -> Void) {
    fk_emptyStateAssertMainThread()
    var copy = templateModel
    configure(&copy)
    templateModel = copy
  }
}
