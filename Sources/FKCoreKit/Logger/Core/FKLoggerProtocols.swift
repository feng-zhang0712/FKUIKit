import Foundation

/// Formats log events into printable strings.
public protocol FKLogFormatting: Sendable {
  /// Builds a user-friendly line.
  ///
  /// - Parameters:
  ///   - event: Original event model.
  ///   - config: Active logger config.
  /// - Returns: Formatted log string.
  func format(event: FKLogEvent, config: FKLoggerConfig) -> String
}

/// Handles file persistence for logs.
public protocol FKLogFileManaging: Sendable {
  /// Writes one formatted line to disk.
  ///
  /// - Parameters:
  ///   - line: Formatted line.
  ///   - timestamp: Event timestamp.
  ///   - config: Active logger config.
  func write(line: String, timestamp: Date, config: FKLoggerConfig)

  /// Returns all log file URLs sorted by creation date.
  func allLogFiles() -> [URL]

  /// Removes every log file managed by logger.
  func clearAllLogs()

  /// Builds a single archive file from all logs.
  ///
  /// - Returns: Temporary file URL when successful, otherwise `nil`.
  func exportLogsArchive() -> URL?
}

/// Prints logs to console.
public protocol FKConsoleOutputting: Sendable {
  /// Outputs one line to console.
  ///
  /// - Parameters:
  ///   - line: Formatted line.
  ///   - level: Severity for style mapping.
  ///   - config: Active logger config.
  func output(line: String, level: FKLogLevel, config: FKLoggerConfig)
}
