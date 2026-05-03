import Foundation

public extension JSONEncoder {
  /// Sets `keyEncodingStrategy` to `.convertToSnakeCase`.
  func fk_applySnakeCaseKeys() {
    keyEncodingStrategy = .convertToSnakeCase
  }

  /// Sets `dateEncodingStrategy` to `.iso8601`.
  func fk_applyISO8601DateStrategy() {
    dateEncodingStrategy = .iso8601
  }

  /// Applies both snake-case keys and ISO-8601 dates (typical JSON API defaults).
  func fk_applyCommonAPIEncodingDefaults() {
    fk_applySnakeCaseKeys()
    fk_applyISO8601DateStrategy()
  }
}
