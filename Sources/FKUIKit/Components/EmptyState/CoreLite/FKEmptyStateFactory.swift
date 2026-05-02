import Foundation

/// Maps ``FKEmptyStateType`` to localized title/description strings.
///
/// Keeps translation lookup out of UI code; safe to call from view models (no UIKit).
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

  /// Localized headline and body for a semantic `type`.
  public func copy(
    for type: FKEmptyStateType,
    variables: [String: String] = [:]
  ) -> (title: String, description: String) {
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
