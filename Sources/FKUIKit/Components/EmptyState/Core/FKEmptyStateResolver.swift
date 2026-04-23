import Foundation

/// Input snapshot consumed by `FKEmptyStateResolver`.
///
/// Keep this struct UI-agnostic so it can be produced from view models, reducers, or services
/// without introducing UIKit dependencies.
public struct FKEmptyStateInputs: Equatable, Sendable {
  public var dataLength: Int?
  public var isLoading: Bool
  public var errorDescription: String?
  public var filtersCount: Int?
  public var searchQuery: String?
  public var hasPermission: Bool?
  public var isOffline: Bool?
  public var isNewUser: Bool?

  public init(
    dataLength: Int? = nil,
    isLoading: Bool = false,
    errorDescription: String? = nil,
    filtersCount: Int? = nil,
    searchQuery: String? = nil,
    hasPermission: Bool? = nil,
    isOffline: Bool? = nil,
    isNewUser: Bool? = nil
  ) {
    self.dataLength = dataLength
    self.isLoading = isLoading
    self.errorDescription = errorDescription
    self.filtersCount = filtersCount
    self.searchQuery = searchQuery
    self.hasPermission = hasPermission
    self.isOffline = isOffline
    self.isNewUser = isNewUser
  }
}

/// Resolver output describing whether an overlay should be shown.
///
/// `.none` means "render normal content", not "unknown state".
public enum FKEmptyStateResolution: Equatable, Sendable {
  case none
  case show(type: FKEmptyStateType)
}

public enum FKEmptyStateResolver {
  /// Resolves a single display type from multiple signals.
  ///
  /// Priority is opinionated by product severity:
  /// permission/offline/loading/error override content emptiness.
  /// This avoids flicker where a transient "no results" might briefly appear during loading.
  ///
  /// Resolution rules (highest priority first):
  /// - **permissionDenied**: explicit access block should be surfaced immediately.
  /// - **offline**: network unavailability typically blocks all recovery paths except settings/retry.
  /// - **loading**: when a request is in-flight, avoid showing empty/noResults placeholders that may be misleading.
  /// - **error**: failures override "empty" so retry affordance is visible.
  /// - **newUser**: optional onboarding state that can override emptiness.
  /// - **content**: when `dataLength > 0`, return `.none` (host should render normal UI).
  /// - **noResults**: when search query is non-empty and there is no data.
  /// - **empty**: default fallback when nothing else applies.
  ///
  /// Trade-offs:
  /// - This resolver is intentionally conservative and UI-agnostic. If your product needs richer
  ///   rules (e.g. distinct "filtered empty" vs "unfiltered empty"), extend `FKEmptyStateInputs`
  ///   and implement a higher-level resolver in your app layer.
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
