import Foundation

public extension TimeInterval {
  /// Whole minutes (rounded toward zero).
  var fk_wholeMinutes: Int {
    Int(self / 60.0)
  }

  /// Whole hours (rounded toward zero).
  var fk_wholeHours: Int {
    Int(self / 3600.0)
  }

  /// Milliseconds representation.
  var fk_milliseconds: Double {
    self * 1000.0
  }

  /// Creates an interval from milliseconds.
  static func fk_fromMilliseconds(_ ms: Double) -> TimeInterval {
    ms / 1000.0
  }
}
