import UIKit

// MARK: - Global template

/// Namespace for a shared `FKEmptyStateModel` template used as an app-wide baseline.
///
/// Typical pattern: `var m = FKEmptyStateGlobalDefaults.template; m.title = "…";` or copy fields manually.
///
/// - Important: Mutate only on the main thread (UIKit).
public enum FKEmptyStateGlobalDefaults {
  /// Baseline typography, colors, and button style; override per screen after copying.
  public nonisolated(unsafe) static var template: FKEmptyStateModel = FKEmptyStateModel(
    buttonStyle: FKEmptyStateButtonStyle(
      title: nil,
      titleColor: .white,
      font: .systemFont(ofSize: 15, weight: .semibold),
      backgroundColor: .systemBlue,
      cornerRadius: 10
    ),
    titleColor: .label,
    descriptionColor: .secondaryLabel,
    backgroundColor: .systemBackground
  )
}
