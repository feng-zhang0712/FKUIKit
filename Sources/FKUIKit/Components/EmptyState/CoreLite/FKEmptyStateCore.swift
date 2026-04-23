import Foundation

/// Platform-neutral EmptyState type set for environments that do not need UIKit rendering.
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

/// UI-agnostic resolver input model used by `FKEmptyStateResolver`.
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

/// Resolver output: show a specific EmptyState type or render normal content.
public enum FKEmptyStateResolution: Equatable, Sendable {
  case none
  case show(type: FKEmptyStateType)
}

public enum FKEmptyStateResolver {
  /// Applies severity-first resolution rules.
  ///
  /// Trade-off: loading and failures take precedence over "no results" to avoid
  /// misleading empty copy while requests are still in-flight.
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

public enum FKEmptyStateLocale: String, CaseIterable, Equatable, Sendable {
  case en
  case zhCN = "zh-CN"
  case ja
  case es
  case ar
}

public struct FKEmptyStateI18nKey: Hashable, Sendable {
  public var rawValue: String
  public init(_ rawValue: String) { self.rawValue = rawValue }
}

public protocol FKEmptyStateTranslating: Sendable {
  func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String
}

public struct FKEmptyStateDictionaryTranslator: FKEmptyStateTranslating {
  public typealias Dictionary = [FKEmptyStateLocale: [FKEmptyStateI18nKey: String]]

  public var dictionary: Dictionary
  public var fallbackLocale: FKEmptyStateLocale

  public init(dictionary: Dictionary, fallbackLocale: FKEmptyStateLocale = .en) {
    self.dictionary = dictionary
    self.fallbackLocale = fallbackLocale
  }

  public func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String {
    let template =
      dictionary[locale]?[key]
      ?? dictionary[fallbackLocale]?[key]
      ?? key.rawValue
    return FKEmptyStateMessageFormat.interpolate(template: template, variables: variables)
  }
}

public enum FKEmptyStateMessageFormat {
  /// Performs simple `{name}` placeholder interpolation.
  ///
  /// This is intentionally lightweight (no plural rules) so CoreLite remains dependency-free.
  public static func interpolate(template: String, variables: [String: String]) -> String {
    guard template.contains("{"), !variables.isEmpty else { return template }
    var result = template
    for (k, v) in variables {
      result = result.replacingOccurrences(of: "{\(k)}", with: v)
    }
    return result
  }
}

public enum FKEmptyStateBuiltInMessages {
  public static let `default` = FKEmptyStateDictionaryTranslator(
    dictionary: [
      .en: [
        FKEmptyStateI18nKey("empty.noResults.description"): "No matches for “{query}”. Try a different keyword.",
      ],
      .zhCN: [
        FKEmptyStateI18nKey("empty.noResults.description"): "没有与“{query}”匹配的结果，请尝试其他关键词。",
      ],
      .ar: [
        FKEmptyStateI18nKey("empty.noResults.description"): "لا توجد نتائج لـ “{query}”. جرّب كلمة مختلفة.",
      ],
    ]
  )
}

public struct FKEmptyStateFactory: Sendable {
  public var locale: FKEmptyStateLocale
  public var translator: any FKEmptyStateTranslating

  public init(
    locale: FKEmptyStateLocale = .en,
    translator: any FKEmptyStateTranslating = FKEmptyStateBuiltInMessages.default
  ) {
    self.locale = locale
    self.translator = translator
  }

  public func noResultsDescription(query: String) -> String {
    // Keep this API narrow on purpose: CoreLite only promises query interpolation,
    // while richer title/description composition lives in the UIKit-side factory.
    translator.translate(
      FKEmptyStateI18nKey("empty.noResults.description"),
      locale: locale,
      variables: ["query": query]
    )
  }
}

