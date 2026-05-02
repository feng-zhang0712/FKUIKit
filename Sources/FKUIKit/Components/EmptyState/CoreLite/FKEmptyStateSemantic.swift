import Foundation

// MARK: - Semantic type

/// Semantic EmptyState categories used for copy presets, analytics, and resolution.
///
/// `FKEmptyStateType` describes *why* an overlay is shown (offline, noResults, permissionDenied…),
/// while the overlay *phase* (loading / empty / error / content; see `FKUIKit`) describes *how* it is rendered.
///
/// - Important: Keep `rawValue` strings stable for analytics and persisted keys.
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

// MARK: - Resolver

/// Input snapshot consumed by ``FKEmptyStateResolver``.
///
/// UI-agnostic: safe to build from view models or services without UIKit.
public struct FKEmptyStateInputs: Equatable, Sendable {
  public var dataLength: Int?
  public var isLoading: Bool
  public var errorDescription: String?
  public var searchQuery: String?
  public var hasPermission: Bool?
  public var isOffline: Bool?
  public var isNewUser: Bool?

  public init(
    dataLength: Int? = nil,
    isLoading: Bool = false,
    errorDescription: String? = nil,
    searchQuery: String? = nil,
    hasPermission: Bool? = nil,
    isOffline: Bool? = nil,
    isNewUser: Bool? = nil
  ) {
    self.dataLength = dataLength
    self.isLoading = isLoading
    self.errorDescription = errorDescription
    self.searchQuery = searchQuery
    self.hasPermission = hasPermission
    self.isOffline = isOffline
    self.isNewUser = isNewUser
  }
}

/// Resolver output: show a semantic type, or render normal content (`.none`).
public enum FKEmptyStateResolution: Equatable, Sendable {
  case none
  case show(type: FKEmptyStateType)
}

public enum FKEmptyStateResolver {
  /// Resolves a single display type from multiple signals (severity-first).
  ///
  /// Priority: permission → offline → loading → error → newUser → has data → noResults → empty.
  /// Loading and errors override “empty” placeholders to avoid misleading copy during requests.
  ///
  /// Extend inputs in your app if you need richer rules (e.g. filtered vs unfiltered empty).
  public static func resolve(_ input: FKEmptyStateInputs) -> FKEmptyStateResolution {
    if input.hasPermission == false { return .show(type: .permissionDenied) }
    if input.isOffline == true { return .show(type: .offline) }
    if input.isLoading { return .show(type: .loading) }
    if input.errorDescription?.isEmpty == false { return .show(type: .error) }
    if input.isNewUser == true { return .show(type: .newUser) }

    if let dataLength = input.dataLength, dataLength > 0 {
      return .none
    }

    if input.searchQuery?.isEmpty == false {
      return .show(type: .noResults)
    }

    return .show(type: .empty)
  }
}
