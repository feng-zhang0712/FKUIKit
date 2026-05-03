import Foundation

public extension BinaryInteger {
  /// `true` when the value is even.
  var fk_isEven: Bool {
    isMultiple(of: 2)
  }

  /// `true` when the value is odd.
  var fk_isOdd: Bool {
    !fk_isEven
  }
}
