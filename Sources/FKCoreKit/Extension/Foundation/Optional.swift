import Foundation

public extension Optional {
  /// Returns the wrapped value or `defaultValue` when `nil`.
  func fk_or(_ defaultValue: @autoclosure () throws -> Wrapped) rethrows -> Wrapped {
    switch self {
    case .none:
      return try defaultValue()
    case let .some(value):
      return value
    }
  }

  /// Returns the wrapped value when non-`nil` and `predicate` holds; otherwise `nil`.
  func fk_filter(_ predicate: (Wrapped) -> Bool) -> Wrapped? {
    flatMap { predicate($0) ? $0 : nil }
  }
}

public extension Optional where Wrapped: Collection {
  /// `true` when `nil` or the wrapped collection is empty.
  var fk_isNilOrEmpty: Bool {
    switch self {
    case .none:
      return true
    case let .some(collection):
      return collection.isEmpty
    }
  }
}
