import Foundation

/// Main entry point for structured logging in FKKit.
public final class FKLogger: @unchecked Sendable {
  /// Shared singleton instance.
  public static let shared = FKLogger()

  /// Current runtime config. Updates are thread-safe.
  public var config: FKLoggerConfig {
    get { stateQueue.sync { _config } }
    set { stateQueue.sync { _config = newValue } }
  }

  fileprivate final class ConsoleOutputter: FKConsoleOutputting {
    func output(line: String, level: FKLogLevel, config: FKLoggerConfig) {
      #if DEBUG
      guard config.isEnabled else { return }
      if config.usesColorizedConsole {
        let reset = "\u{001B}[0m"
        Swift.print(level.ansiColorCode + line + reset)
      } else {
        Swift.print(line)
      }
      #endif
    }
  }

  private let stateQueue = DispatchQueue(label: "com.fkkit.logger.state", qos: .utility)
  private let workQueue = DispatchQueue(label: "com.fkkit.logger.work", qos: .utility, attributes: .concurrent)
  private let formatter: FKLogFormatting
  private let fileManager: FKLogFileManaging
  private let consoleOutputter: FKConsoleOutputting
  private var _config: FKLoggerConfig

  /// Creates a logger with custom collaborators.
  ///
  /// - Parameters:
  ///   - config: Initial logger config.
  ///   - formatter: Event formatter.
  ///   - fileManager: File persistence manager.
  ///   - consoleOutputter: Console output manager.
  public init(
    config: FKLoggerConfig = .default,
    formatter: FKLogFormatting = FKLogFormatter(),
    fileManager: FKLogFileManaging = FKLogFileManager(),
    consoleOutputter: FKConsoleOutputting? = nil
  ) {
    _config = config
    self.formatter = formatter
    self.fileManager = fileManager
    self.consoleOutputter = consoleOutputter ?? ConsoleOutputter()
  }

  /// Installs crash handlers and enables global crash capture.
  public func installCrashCapture() {
    FKCrashMonitor.install(logger: self)
  }

  /// Enables or disables one specific log level.
  ///
  /// - Parameters:
  ///   - isEnabled: Level switch.
  ///   - level: Target level.
  public func setLevel(_ level: FKLogLevel, isEnabled: Bool) {
    stateQueue.sync {
      if isEnabled {
        _config.enabledLevels.insert(level)
      } else {
        _config.enabledLevels.remove(level)
      }
    }
  }

  /// Updates config atomically.
  ///
  /// - Parameter transform: Mutation closure for current config.
  public func updateConfig(_ transform: (inout FKLoggerConfig) -> Void) {
    stateQueue.sync {
      transform(&_config)
    }
  }

  /// Emits a verbose log line.
  public func verbose(
    _ message: @autoclosure @escaping () -> String,
    metadata: [String: String] = [:],
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(
      .verbose,
      message: message,
      metadata: metadata,
      file: file,
      function: function,
      line: line
    )
  }

  /// Emits a debug log line.
  public func debug(
    _ message: @autoclosure @escaping () -> String,
    metadata: [String: String] = [:],
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(.debug, message: message, metadata: metadata, file: file, function: function, line: line)
  }

  /// Emits an info log line.
  public func info(
    _ message: @autoclosure @escaping () -> String,
    metadata: [String: String] = [:],
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(.info, message: message, metadata: metadata, file: file, function: function, line: line)
  }

  /// Emits a warning log line.
  public func warning(
    _ message: @autoclosure @escaping () -> String,
    metadata: [String: String] = [:],
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(.warning, message: message, metadata: metadata, file: file, function: function, line: line)
  }

  /// Emits an error log line.
  public func error(
    _ message: @autoclosure @escaping () -> String,
    metadata: [String: String] = [:],
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
  ) {
    log(.error, message: message, metadata: metadata, file: file, function: function, line: line)
  }

  /// Captures custom exception payload.
  public func captureException(
    name: String,
    reason: String,
    metadata: [String: String] = [:]
  ) {
    FKCrashMonitor.captureCustomException(name: name, reason: reason, metadata: metadata)
  }

  /// Captures network request and response context.
  public func captureNetwork(
    request: URLRequest,
    response: URLResponse?,
    data: Data?,
    error: Error?
  ) {
    FKCrashMonitor.captureNetworkLog(
      request: request,
      response: response,
      data: data,
      error: error
    )
  }

  /// Returns all current log files.
  public func allLogFiles() -> [URL] {
    fileManager.allLogFiles()
  }

  /// Removes all persisted log files.
  public func clearLogFiles() {
    fileManager.clearAllLogs()
  }

  /// Exports all logs into one temporary file for share sheet.
  public func exportLogArchive() -> URL? {
    fileManager.exportLogsArchive()
  }

  /// Flushes queue synchronously. Useful before app exits.
  public func flushSynchronously() {
    workQueue.sync(flags: .barrier) {}
  }

  func log(
    _ level: FKLogLevel,
    message: @escaping () -> String,
    metadata: [String: String],
    file: String,
    function: String,
    line: Int
  ) {
    let currentConfig = stateQueue.sync { _config }
    guard shouldLog(level: level, config: currentConfig) else { return }
    let resolvedMessage = message()

    workQueue.async(flags: .barrier) { [weak self] in
      guard let self else { return }
      let event = FKLogEvent(
        level: level,
        message: resolvedMessage,
        file: file,
        function: function,
        line: line,
        metadata: metadata
      )
      let lineText = self.formatter.format(event: event, config: currentConfig)
      self.consoleOutputter.output(line: lineText, level: level, config: currentConfig)
      if currentConfig.persistsToFile {
        self.fileManager.write(line: lineText, timestamp: event.timestamp, config: currentConfig)
      }
    }
  }

  private func shouldLog(level: FKLogLevel, config: FKLoggerConfig) -> Bool {
    guard config.isEnabled else { return false }
    return config.enabledLevels.contains(level)
  }
}
