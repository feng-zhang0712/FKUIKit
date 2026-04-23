import UIKit

/// Singleton manager that stores app-wide defaults for `FKEmptyState`.
///
/// Mutate `templateModel` once during app launch, then override per-screen as needed.
/// All APIs are main-thread constrained because UIKit-backed values are involved.
///
/// Override strategy:
/// - Global defaults live in `FKEmptyStateGlobalDefaults.template`.
/// - `FKEmptyStateManager.templateModel` reads/writes that template.
/// - Screen-level code should copy the template (via `fk_setEmptyState` helpers) and then mutate
///   the copy to avoid leaking changes across screens.
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
  ///
  /// Prefer calling this during app startup (or scene setup) to establish consistent branding.
  public func configureTemplate(_ configure: (inout FKEmptyStateModel) -> Void) {
    fk_emptyStateAssertMainThread()
    var copy = templateModel
    configure(&copy)
    templateModel = copy
  }
}
