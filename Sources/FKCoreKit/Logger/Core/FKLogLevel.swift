import Foundation

/// Log severity levels supported by `FKLogger`.
public enum FKLogLevel: Int, CaseIterable, Comparable, Sendable {
  /// Verbose details used for deep diagnostics.
  case verbose = 0
  /// Debug details intended for development.
  case debug
  /// Informational message for normal flow.
  case info
  /// Warning message that indicates a potential issue.
  case warning
  /// Error message for failures.
  case error

  /// A short uppercase label used in formatted output.
  public var label: String {
    switch self {
    case .verbose: "VERBOSE"
    case .debug: "DEBUG"
    case .info: "INFO"
    case .warning: "WARNING"
    case .error: "ERROR"
    }
  }

  /// Emoji marker used to quickly identify severity.
  public var emoji: String {
    switch self {
    case .verbose: "🔎"
    case .debug: "🐞"
    case .info: "ℹ️"
    case .warning: "⚠️"
    case .error: "❌"
    }
  }

  /// ANSI color code for terminal output.
  public var ansiColorCode: String {
    switch self {
    case .verbose: "\u{001B}[0;37m"
    case .debug: "\u{001B}[0;36m"
    case .info: "\u{001B}[0;32m"
    case .warning: "\u{001B}[0;33m"
    case .error: "\u{001B}[0;31m"
    }
  }

  /// Compares two log levels based on severity order.
  public static func < (lhs: FKLogLevel, rhs: FKLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
