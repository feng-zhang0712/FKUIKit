//
// FKStickyManager.swift
//

import Foundation

/// Shared manager used to provide app-wide sticky defaults.
@MainActor
public final class FKStickyManager {
  /// Shared singleton.
  public static let shared = FKStickyManager()

  /// Template configuration inherited by convenience APIs.
  public var templateConfiguration: FKStickyConfiguration {
    get { FKStickyGlobalDefaults.configuration }
    set { FKStickyGlobalDefaults.configuration = newValue }
  }

  private init() {}
}
