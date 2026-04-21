import Foundation

/// Static collection utility helpers.
public enum FKUtilsCollection {
  /// Returns unique values while preserving order.
  public static func unique<T: Hashable>(_ values: [T]) -> [T] {
    var seen = Set<T>()
    return values.filter { seen.insert($0).inserted }
  }

  /// Returns sorted values by key path.
  public static func sort<T, V: Comparable>(_ values: [T], by keyPath: KeyPath<T, V>, ascending: Bool = true) -> [T] {
    values.sorted { lhs, rhs in
      ascending ? lhs[keyPath: keyPath] < rhs[keyPath: keyPath] : lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
    }
  }

  /// Splits array into chunks.
  public static func chunk<T>(_ values: [T], size: Int) -> [[T]] {
    guard size > 0 else { return [] }
    var result: [[T]] = []
    result.reserveCapacity((values.count + size - 1) / size)
    var index = 0
    while index < values.count {
      let end = min(index + size, values.count)
      result.append(Array(values[index..<end]))
      index += size
    }
    return result
  }

  /// Filters dictionary removing null and empty values.
  public static func compactDictionary(_ dictionary: [String: Any?]) -> [String: Any] {
    dictionary.reduce(into: [String: Any]()) { partial, pair in
      if let value = pair.value { partial[pair.key] = value }
    }
  }

  /// Converts dictionary to JSON text.
  public static func jsonString(from dictionary: [String: Any], prettyPrinted: Bool = false) -> String? {
    guard JSONSerialization.isValidJSONObject(dictionary) else { return nil }
    let options: JSONSerialization.WritingOptions = prettyPrinted ? [.prettyPrinted] : []
    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: options) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  /// Decodes dictionary into model.
  public static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any], decoder: JSONDecoder = JSONDecoder()) -> T? {
    guard JSONSerialization.isValidJSONObject(dictionary),
          let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
      return nil
    }
    return try? decoder.decode(type, from: data)
  }
}

public extension Array {
  /// Returns safe element at index.
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

public extension Dictionary {
  /// Returns typed value for key.
  func value<T>(for key: Key, as type: T.Type = T.self) -> T? {
    self[key] as? T
  }
}
