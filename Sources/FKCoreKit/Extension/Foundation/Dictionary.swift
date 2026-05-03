import Foundation

public extension Dictionary {
  /// Merges `other` into `self`, using `combine` when duplicate keys exist.
  mutating func fk_merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) -> Value) {
    merge(other, uniquingKeysWith: combine)
  }

  /// Returns a new dictionary by merging `other`, using `combine` when duplicate keys exist.
  func fk_merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) -> Value) -> [Key: Value] {
    merging(other, uniquingKeysWith: combine)
  }
}

public extension Dictionary {
  /// Maps keys while preserving values; duplicate mapped keys keep the last occurrence.
  func fk_mapKeys<NewKey: Hashable>(_ transform: (Key) throws -> NewKey) rethrows -> [NewKey: Value] {
    var result: [NewKey: Value] = [:]
    for (key, value) in self {
      result[try transform(key)] = value
    }
    return result
  }

  /// Maps values while preserving keys; stops at the first thrown error.
  func fk_mapValuesThrowing<NewValue>(_ transform: (Value) throws -> NewValue) rethrows -> [Key: NewValue] {
    var result: [Key: NewValue] = [:]
    result.reserveCapacity(count)
    for (key, value) in self {
      result[key] = try transform(value)
    }
    return result
  }
}
