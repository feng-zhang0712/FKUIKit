import Foundation

public extension Date {
  /// Start of the same calendar day in the given calendar and time zone.
  func fk_startOfDay(calendar: Calendar = .current, timeZone: TimeZone? = nil) -> Date {
    var cal = calendar
    if let timeZone {
      cal.timeZone = timeZone
    }
    return cal.startOfDay(for: self)
  }

  /// End of the same calendar day (one second before next midnight) in the given calendar and time zone.
  func fk_endOfDay(calendar: Calendar = .current, timeZone: TimeZone? = nil) -> Date {
    let start = fk_startOfDay(calendar: calendar, timeZone: timeZone)
    var cal = calendar
    if let timeZone {
      cal.timeZone = timeZone
    }
    guard let next = cal.date(byAdding: .day, value: 1, to: start) else { return self }
    return next.addingTimeInterval(-1)
  }

  /// Adds calendar components using the provided calendar.
  func fk_byAdding(_ components: DateComponents, calendar: Calendar = .current) -> Date? {
    calendar.date(byAdding: components, to: self)
  }

  /// ISO-8601 formatted string in UTC (`yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX`).
  func fk_iso8601UTCString(fractionalSeconds: Bool = true) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime]
    if fractionalSeconds {
      formatter.formatOptions.insert(.withFractionalSeconds)
    }
    return formatter.string(from: self)
  }
}

public extension Date {
  /// Returns `true` when this date is strictly after `other`.
  func fk_isAfter(_ other: Date) -> Bool {
    self > other
  }

  /// Returns `true` when this date is strictly before `other`.
  func fk_isBefore(_ other: Date) -> Bool {
    self < other
  }

  /// Returns `true` when this date is between `start` and `end` inclusively.
  func fk_isBetween(_ start: Date, and end: Date) -> Bool {
    self >= start && self <= end
  }
}
