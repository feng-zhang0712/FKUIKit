import Foundation

public extension Collection {
  /// Safe element at index; `nil` when out of range.
  subscript(fk_safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

public extension Collection where Element: Equatable {
  /// Returns the number of occurrences of `element`.
  func fk_count(of element: Element) -> Int {
    filter { $0 == element }.count
  }
}

public extension BidirectionalCollection {
  /// Last element satisfying `predicate`, scanning from the end.
  func fk_last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
    try reversed().first(where: predicate)
  }
}
