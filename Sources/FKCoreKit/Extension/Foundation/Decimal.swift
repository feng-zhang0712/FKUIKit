import Foundation

public extension Decimal {
  /// Bridge to `Double` for interop with APIs that expect floating-point values.
  var fk_doubleValue: Double {
    NSDecimalNumber(decimal: self).doubleValue
  }

  /// Rounds using `NSDecimalRound` with the given scale and mode.
  func fk_rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
    var value = self
    var result = Decimal()
    NSDecimalRound(&result, &value, scale, mode)
    return result
  }
}
