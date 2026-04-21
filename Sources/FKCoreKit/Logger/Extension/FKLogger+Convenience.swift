import Foundation

/// Namespace shortcuts for one-line global logging usage.
public extension FKCoreKit {
  /// Global logger instance.
  static var logger: FKLogger { FKLogger.shared }
}

/// Logs a verbose message through singleton.
public func FKLogV(
  _ message: @autoclosure @escaping () -> String,
  metadata: [String: String] = [:],
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) {
  FKLogger.shared.verbose(message(), metadata: metadata, file: file, function: function, line: line)
}

/// Logs a debug message through singleton.
public func FKLogD(
  _ message: @autoclosure @escaping () -> String,
  metadata: [String: String] = [:],
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) {
  FKLogger.shared.debug(message(), metadata: metadata, file: file, function: function, line: line)
}

/// Logs an info message through singleton.
public func FKLogI(
  _ message: @autoclosure @escaping () -> String,
  metadata: [String: String] = [:],
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) {
  FKLogger.shared.info(message(), metadata: metadata, file: file, function: function, line: line)
}

/// Logs a warning message through singleton.
public func FKLogW(
  _ message: @autoclosure @escaping () -> String,
  metadata: [String: String] = [:],
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) {
  FKLogger.shared.warning(message(), metadata: metadata, file: file, function: function, line: line)
}

/// Logs an error message through singleton.
public func FKLogE(
  _ message: @autoclosure @escaping () -> String,
  metadata: [String: String] = [:],
  file: String = #fileID,
  function: String = #function,
  line: Int = #line
) {
  FKLogger.shared.error(message(), metadata: metadata, file: file, function: function, line: line)
}

public extension FKLogger {
  /// Pretty prints any value using Foundation reflection and JSON conversion.
  ///
  /// - Parameters:
  ///   - value: Value to inspect.
  ///   - level: Log level for output.
  ///   - file: Source filename.
  ///   - function: Source function.
  ///   - line: Source line.
  func dumpValue(
    _ value: Any,
    level: FKLogLevel = .debug,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(level, message: { self.formatAny(value) }, metadata: [:], file: file, function: function, line: line)
  }

  /// Pretty prints an encodable model in JSON style.
  ///
  /// - Parameters:
  ///   - value: Encodable value.
  ///   - level: Log level for output.
  ///   - file: Source filename.
  ///   - function: Source function.
  ///   - line: Source line.
  func dumpEncodable<T: Encodable>(
    _ value: T,
    level: FKLogLevel = .debug,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(value)
      let text = String(data: data, encoding: .utf8) ?? String(describing: value)
      log(level, message: { text }, metadata: ["dump": "encodable"], file: file, function: function, line: line)
    } catch {
      log(
        level,
        message: { String(describing: value) },
        metadata: ["dump_error": error.localizedDescription],
        file: file,
        function: function,
        line: line
      )
    }
  }

  private func formatAny(_ value: Any) -> String {
    if JSONSerialization.isValidJSONObject(value),
       let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]),
       let text = String(data: data, encoding: .utf8) {
      return text
    }
    return String(reflecting: value)
  }
}
