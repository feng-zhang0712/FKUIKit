import Foundation

/// Semantic EmptyState categories used for copy presets, analytics, and resolution.
///
/// `FKEmptyStateType` describes *why* an overlay is shown (offline, noResults, permissionDenied...),
/// while `FKEmptyStatePhase` describes *how* it is rendered (loading vs empty/error vs hidden).
///
/// Design notes:
/// - Keep cases stable to avoid breaking i18n keys and analytics dashboards.
/// - Prefer adding a new case over reusing an existing one with different meaning.
public enum FKEmptyStateType: String, CaseIterable, Equatable, Sendable {
  case empty
  case noResults = "no_results"
  case error
  case offline
  case permissionDenied = "permission_denied"
  case notFound = "not_found"
  case maintenance
  case loading
  case newUser = "new_user"
}

/// Optional screen-level context hint used to tune presets/layout decisions.
///
/// This does not change core rendering logic by itself; it is carried on the model so higher layers
/// (factories/resolvers) can select copy and actions more appropriately.
public enum FKEmptyStateLayoutContext: String, CaseIterable, Equatable, Sendable {
  case list
  case table
  case search
  case detail
  case dialog
  case drawer
  case card
  case fullPage = "full_page"
  case section
}

/// Spacing density hint for presets.
///
/// The UIKit renderer currently uses explicit values from `FKEmptyStateModel` (spacing/insets/etc.).
/// This enum is kept for future-proofing and for app-level factories to pick reasonable defaults.
public enum FKEmptyStateDensity: String, CaseIterable, Equatable, Sendable {
  case compact
  case regular
  case comfortable
}

/// Preferred axis for composable/slot-based layouts.
///
/// The current UIKit implementation uses a vertical stack by default; this is kept as a semantic
/// signal for custom renderers or future layout variants.
public enum FKEmptyStateAxis: String, CaseIterable, Equatable, Sendable {
  case vertical
  case horizontal
}
