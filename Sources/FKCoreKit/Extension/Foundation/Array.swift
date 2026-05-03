import Foundation

public extension Array {
  /// Splits the array into chunks of at most `size` elements (last chunk may be smaller).
  func fk_chunked(into size: Int) -> [[Element]] {
    guard size > 0 else { return [] }
    var result: [[Element]] = []
    result.reserveCapacity(Swift.max(1, count / size))
    var start = startIndex
    while start < endIndex {
      let end = index(start, offsetBy: size, limitedBy: endIndex) ?? endIndex
      result.append(Array(self[start..<end]))
      start = end
    }
    return result
  }
}

public extension Array where Element: Hashable {
  /// Preserves order while removing duplicate elements.
  var fk_uniqued: [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

public extension Array {
  /// Rotates elements left by `positions` (default 1).
  func fk_rotatedLeft(by positions: Int = 1) -> [Element] {
    guard !isEmpty, positions != 0 else { return self }
    let n = count
    let k = ((positions % n) + n) % n
    return Array(self[k..<n] + self[0..<k])
  }
}
