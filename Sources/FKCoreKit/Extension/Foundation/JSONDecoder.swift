import Foundation

public extension JSONDecoder {
  /// Sets `keyDecodingStrategy` to `.convertFromSnakeCase`.
  func fk_applySnakeCaseKeys() {
    keyDecodingStrategy = .convertFromSnakeCase
  }

  /// Sets `dateDecodingStrategy` to `.iso8601` (system parser; fractional seconds depend on OS/parser behavior).
  func fk_applyISO8601DateStrategy() {
    dateDecodingStrategy = .iso8601
  }

  /// Applies both snake-case keys and ISO-8601 dates (typical JSON API defaults).
  func fk_applyCommonAPIDecodingDefaults() {
    fk_applySnakeCaseKeys()
    fk_applyISO8601DateStrategy()
  }
}
