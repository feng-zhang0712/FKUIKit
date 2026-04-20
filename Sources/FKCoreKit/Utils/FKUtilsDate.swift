import Foundation

/// Protocol describing date utility capabilities.
public protocol FKDateUtilsProviding {
  /// Converts a date to a formatted string.
  func string(from date: Date, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> String
  /// Parses a string into a date using the supplied format.
  func date(from string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Date?
  /// Converts date to timestamp in seconds.
  func timestamp(from date: Date) -> TimeInterval
  /// Creates date from timestamp in seconds.
  func date(fromTimestamp timestamp: TimeInterval) -> Date
  /// Produces a localized relative description.
  func relativeDescription(for date: Date, reference: Date, calendar: Calendar) -> String
  /// Compares two dates with granularity.
  func compare(_ lhs: Date, _ rhs: Date, granularity: Calendar.Component, calendar: Calendar) -> ComparisonResult
  /// Adds date components to a date.
  func adding(_ components: DateComponents, to date: Date, calendar: Calendar) -> Date?
  /// Returns the weekday index from calendar.
  func weekday(for date: Date, calendar: Calendar) -> Int
  /// Returns the month index from calendar.
  func month(for date: Date, calendar: Calendar) -> Int
  /// Validates a date string against format.
  func isValid(_ string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Bool
}

/// Default implementation of ``FKDateUtilsProviding``.
public struct FKDateUtilsProvider: FKDateUtilsProviding {
  private let formatterCache = NSCache<NSString, DateFormatter>()

  public init() {}

  public func string(from date: Date, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> String {
    let formatter = formatter(for: format, timeZone: timeZone, locale: locale, calendar: calendar)
    return formatter.string(from: date)
  }

  public func date(from string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Date? {
    let formatter = formatter(for: format, timeZone: timeZone, locale: locale, calendar: calendar)
    return formatter.date(from: string)
  }

  public func timestamp(from date: Date) -> TimeInterval { date.timeIntervalSince1970 }

  public func date(fromTimestamp timestamp: TimeInterval) -> Date {
    Date(timeIntervalSince1970: timestamp)
  }

  public func relativeDescription(for date: Date, reference: Date, calendar: Calendar) -> String {
    let seconds = Int(reference.timeIntervalSince(date))
    if seconds < 0 { return string(from: date, format: "yyyy-MM-dd HH:mm", timeZone: nil, locale: nil, calendar: calendar) }
    if seconds < 30 { return "just now" }
    if seconds < 60 { return "\(seconds) seconds ago" }

    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes) minutes ago" }

    let hours = minutes / 60
    if hours < 24 { return "\(hours) hours ago" }
    if calendar.isDateInYesterday(date) { return "yesterday" }
    if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: reference), calendar.isDate(date, inSameDayAs: twoDaysAgo) {
      return "the day before yesterday"
    }

    return string(from: date, format: "yyyy-MM-dd", timeZone: nil, locale: nil, calendar: calendar)
  }

  public func compare(_ lhs: Date, _ rhs: Date, granularity: Calendar.Component, calendar: Calendar) -> ComparisonResult {
    calendar.compare(lhs, to: rhs, toGranularity: granularity)
  }

  public func adding(_ components: DateComponents, to date: Date, calendar: Calendar) -> Date? {
    calendar.date(byAdding: components, to: date)
  }

  public func weekday(for date: Date, calendar: Calendar) -> Int {
    calendar.component(.weekday, from: date)
  }

  public func month(for date: Date, calendar: Calendar) -> Int {
    calendar.component(.month, from: date)
  }

  public func isValid(_ string: String, format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> Bool {
    guard let parsed = date(from: string, format: format, timeZone: timeZone, locale: locale, calendar: calendar) else {
      return false
    }
    return self.string(from: parsed, format: format, timeZone: timeZone, locale: locale, calendar: calendar) == string
  }

  /// Returns a cached date formatter for a unique context.
  private func formatter(for format: String, timeZone: TimeZone?, locale: Locale?, calendar: Calendar?) -> DateFormatter {
    let calendarIdentifier = calendar.map { String(describing: $0.identifier) } ?? "system"
    let key = "\(format)|\(timeZone?.identifier ?? "system")|\(locale?.identifier ?? "system")|\(calendarIdentifier)" as NSString
    if let cached = formatterCache.object(forKey: key) { return cached }
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = timeZone
    formatter.locale = locale
    formatter.calendar = calendar
    formatterCache.setObject(formatter, forKey: key)
    return formatter
  }
}

/// Static facade for date utilities.
public enum FKUtilsDate {
  /// Thread-safe provider storage used to avoid shared mutable global state.
  private final class ProviderStore: @unchecked Sendable {
    private let lock = NSLock()
    private var provider: FKDateUtilsProviding = FKDateUtilsProvider()

    func set(_ provider: FKDateUtilsProviding) {
      lock.lock()
      defer { lock.unlock() }
      self.provider = provider
    }

    func get() -> FKDateUtilsProviding {
      lock.lock()
      defer { lock.unlock() }
      return provider
    }
  }

  private static let store = ProviderStore()

  /// Replaces the default provider for testing or extension.
  public static func register(provider newProvider: FKDateUtilsProviding) {
    store.set(newProvider)
  }

  /// Converts a date to a formatted string.
  public static func string(from date: Date, format: String, timeZone: TimeZone? = nil, locale: Locale? = nil, calendar: Calendar? = nil) -> String {
    let current = store.get()
    return current.string(from: date, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  /// Parses a string into a date.
  public static func date(from string: String, format: String, timeZone: TimeZone? = nil, locale: Locale? = nil, calendar: Calendar? = nil) -> Date? {
    let current = store.get()
    return current.date(from: string, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }

  /// Converts date to timestamp in seconds.
  public static func timestamp(from date: Date) -> TimeInterval {
    let current = store.get()
    return current.timestamp(from: date)
  }

  /// Creates date from timestamp.
  public static func date(fromTimestamp timestamp: TimeInterval) -> Date {
    let current = store.get()
    return current.date(fromTimestamp: timestamp)
  }

  /// Produces a readable relative description.
  public static func relativeDescription(for date: Date, reference: Date = Date(), calendar: Calendar = .current) -> String {
    let current = store.get()
    return current.relativeDescription(for: date, reference: reference, calendar: calendar)
  }

  /// Compares two dates at granularity.
  public static func compare(_ lhs: Date, _ rhs: Date, granularity: Calendar.Component = .day, calendar: Calendar = .current) -> ComparisonResult {
    let current = store.get()
    return current.compare(lhs, rhs, granularity: granularity, calendar: calendar)
  }

  /// Adds components to date.
  public static func add(_ components: DateComponents, to date: Date, calendar: Calendar = .current) -> Date? {
    let current = store.get()
    return current.adding(components, to: date, calendar: calendar)
  }

  /// Returns weekday index.
  public static func weekday(for date: Date, calendar: Calendar = .current) -> Int {
    let current = store.get()
    return current.weekday(for: date, calendar: calendar)
  }

  /// Returns month index.
  public static func month(for date: Date, calendar: Calendar = .current) -> Int {
    let current = store.get()
    return current.month(for: date, calendar: calendar)
  }

  /// Validates whether a date string matches a format.
  public static func isValidDate(_ string: String, format: String, timeZone: TimeZone? = nil, locale: Locale? = nil, calendar: Calendar? = nil) -> Bool {
    let current = store.get()
    return current.isValid(string, format: format, timeZone: timeZone, locale: locale, calendar: calendar)
  }
}
