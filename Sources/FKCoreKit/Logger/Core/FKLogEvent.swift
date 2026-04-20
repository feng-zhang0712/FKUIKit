import Foundation

/// A normalized log payload passed through formatter and output pipelines.
public struct FKLogEvent: Sendable {
  /// Severity level for this event.
  public let level: FKLogLevel
  /// Message body provided by caller.
  public let message: String
  /// Source filename where log was emitted.
  public let file: String
  /// Source function where log was emitted.
  public let function: String
  /// Source line where log was emitted.
  public let line: Int
  /// Event creation time.
  public let timestamp: Date
  /// Additional context values.
  public let metadata: [String: String]

  /// Creates a new event model.
  ///
  /// - Parameters:
  ///   - level: Severity level.
  ///   - message: Message body.
  ///   - file: Source filename.
  ///   - function: Source function.
  ///   - line: Source line number.
  ///   - timestamp: Event timestamp.
  ///   - metadata: Optional metadata dictionary.
  public init(
    level: FKLogLevel,
    message: String,
    file: String,
    function: String,
    line: Int,
    timestamp: Date = Date(),
    metadata: [String: String] = [:]
  ) {
    self.level = level
    self.message = message
    self.file = file
    self.function = function
    self.line = line
    self.timestamp = timestamp
    self.metadata = metadata
  }
}
