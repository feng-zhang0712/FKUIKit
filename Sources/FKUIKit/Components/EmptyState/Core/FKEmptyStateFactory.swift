import Foundation

/// Copy builder that maps semantic state to localized EmptyState text.
///
/// This keeps translation lookup out of view code, so teams can swap translators
/// (dictionary/remote/A-B variants) without touching rendering logic.
public struct FKEmptyStateFactory: Sendable {
  public var locale: FKEmptyStateLocale
  public var translator: any FKEmptyStateTranslating

  /// Creates a copy factory for a given `locale` and translation backend.
  ///
  /// - Parameters:
  ///   - locale: Locale to use when requesting messages from `translator`.
  ///   - translator: Translation backend (built-in dictionary by default).
  ///
  /// - Note: The factory does not touch UIKit and can be used in view models or reducers.
  public init(
    locale: FKEmptyStateLocale = .en,
    translator: any FKEmptyStateTranslating = FKEmptyStateBuiltInMessages.default
  ) {
    self.locale = locale
    self.translator = translator
  }

  /// Returns localized `(title, description)` for a given semantic `type`.
  ///
  /// - Parameters:
  ///   - type: Semantic state (`offline`, `noResults`, `permissionDenied`, etc.).
  ///   - variables: Placeholder values used for message interpolation (e.g. `["query": "camera"]`).
  ///
  /// - Important: Interpolation uses a lightweight `{token}` replacement strategy (see
  ///   `FKEmptyStateMessageFormat.interpolate`). Unknown placeholders are preserved to surface
  ///   integration mistakes in QA.
  public func copy(
    for type: FKEmptyStateType,
    variables: [String: String] = [:]
  ) -> (title: String, description: String) {
    // Use camelCase aliases for keys that differ from `rawValue` naming.
    // Trade-off: we keep backward-compatible key names instead of forcing a breaking key migration.
    let prefix = "empty.\(keySegment(for: type))"
    let title = translator.translate(FKEmptyStateI18nKey("\(prefix).title"), locale: locale, variables: variables)
    let desc = translator.translate(FKEmptyStateI18nKey("\(prefix).description"), locale: locale, variables: variables)
    return (title, desc)
  }

  public func actionTitle(
    _ key: FKEmptyStateI18nKey,
    variables: [String: String] = [:]
  ) -> String {
    translator.translate(key, locale: locale, variables: variables)
  }

  /// Maps semantic `FKEmptyStateType` to i18n key segments.
  ///
  /// Some cases intentionally use camelCase segments (e.g. `permissionDenied`) instead of
  /// `rawValue` to keep stable keys across earlier naming conventions.
  private func keySegment(for type: FKEmptyStateType) -> String {
    switch type {
    case .noResults: return "noResults"
    case .permissionDenied: return "permissionDenied"
    case .notFound: return "notFound"
    case .newUser: return "newUser"
    default: return type.rawValue
    }
  }
}
