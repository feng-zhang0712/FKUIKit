import Foundation

// MARK: - Layout context

/// Optional screen-level context for presets and analytics (carried on ``FKEmptyStateConfiguration``).
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

// MARK: - Density & axis

/// Spacing density hint for app-level presets (explicit model metrics override this).
public enum FKEmptyStateDensity: String, CaseIterable, Equatable, Sendable {
  case compact
  case regular
  case comfortable
}

/// Preferred stack axis for future layout variants; current UIKit renderer uses a vertical stack.
public enum FKEmptyStateAxis: String, CaseIterable, Equatable, Sendable {
  case vertical
  case horizontal
}
