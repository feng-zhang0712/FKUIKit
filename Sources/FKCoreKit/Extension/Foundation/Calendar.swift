import Foundation

public extension Calendar {
  /// Start of the week-of-year interval containing `date`, if defined for this calendar.
  func fk_startOfWeek(for date: Date) -> Date? {
    dateInterval(of: .weekOfYear, for: date)?.start
  }

  /// Last instant inside the week-of-year interval containing `date` (one unit before the interval’s `end`).
  ///
  /// - Note: `dateInterval(of:for:).end` is exclusive; this value is suitable for inclusive “end of week” UI copy.
  func fk_endOfWeek(for date: Date) -> Date? {
    guard let interval = dateInterval(of: .weekOfYear, for: date) else { return nil }
    return interval.end.addingTimeInterval(-1)
  }

  /// Signed day difference between calendar midnights of `fromDate` and `toDate` (may be negative).
  func fk_numberOfDays(from fromDate: Date, to toDate: Date) -> Int? {
    let start = startOfDay(for: fromDate)
    let end = startOfDay(for: toDate)
    return dateComponents([.day], from: start, to: end).day
  }
}
