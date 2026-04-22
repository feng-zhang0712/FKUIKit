import Foundation

/// Shared manager used to provide app-wide sticky defaults.
public final class FKStickyManager: Sendable {
  /// Shared singleton.
  public static let shared = FKStickyManager()

  /// Template configuration inherited by convenience APIs.
  public var templateConfiguration: FKStickyConfiguration {
    get { FKStickyGlobalDefaults.configuration }
    set { FKStickyGlobalDefaults.configuration = newValue }
  }

  /// Updates global defaults from any thread.
  ///
  /// - Parameter update: In-place configuration mutation closure.
  public func updateTemplateConfiguration(_ update: (inout FKStickyConfiguration) -> Void) {
    var configuration = FKStickyGlobalDefaults.configuration
    update(&configuration)
    FKStickyGlobalDefaults.configuration = configuration
  }

  private init() {}
}
