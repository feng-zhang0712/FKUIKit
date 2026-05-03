import Foundation

public extension Sequence {
  /// Returns a dictionary grouping elements by key; later elements overwrite earlier ones for duplicate keys.
  func fk_grouped<Key: Hashable>(by keyForValue: (Element) throws -> Key) rethrows -> [Key: Element] {
    var dict: [Key: Element] = [:]
    for element in self {
      let key = try keyForValue(element)
      dict[key] = element
    }
    return dict
  }

  /// Returns a dictionary grouping elements into arrays by key.
  func fk_grouping<Key: Hashable>(by keyForValue: (Element) throws -> Key) rethrows -> [Key: [Element]] {
    try Dictionary(grouping: self, by: keyForValue)
  }

  /// `true` when no element satisfies `predicate`.
  func fk_noneSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
    try !contains(where: predicate)
  }
}

public extension Sequence where Element: AdditiveArithmetic {
  /// Sum of elements; returns `.zero` for an empty sequence.
  func fk_sum() -> Element {
    reduce(.zero, +)
  }
}
