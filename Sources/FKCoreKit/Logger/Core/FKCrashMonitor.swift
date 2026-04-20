import Foundation

#if canImport(Darwin)
import Darwin
#endif

private func fkUncaughtExceptionHandler(_ exception: NSException) {
  FKCrashMonitor.handleUncaughtException(exception)
}

/// Captures uncaught exceptions and common fatal signals.
public final class FKCrashMonitor: @unchecked Sendable {
  private nonisolated(unsafe) static weak var logger: FKLogger?
  private nonisolated(unsafe) static var isInstalled = false
  private static let handledSignals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]

  /// Installs signal and exception handlers.
  ///
  /// - Parameter logger: Logger instance used for persistence.
  public static func install(logger: FKLogger) {
    guard !isInstalled else { return }
    self.logger = logger
    NSSetUncaughtExceptionHandler(fkUncaughtExceptionHandler)
    handledSignals.forEach { signalCode in
      signal(signalCode, Self.signalHandler)
    }
    isInstalled = true
  }

  /// Logs a custom exception-like event.
  ///
  /// - Parameters:
  ///   - name: Exception name.
  ///   - reason: Detail string.
  ///   - metadata: Extra context.
  public static func captureCustomException(
    name: String,
    reason: String,
    metadata: [String: String] = [:]
  ) {
    var payload = metadata
    payload["source"] = "custom_exception"
    logger?.error("Exception[\(name)]: \(reason)", metadata: payload)
  }

  /// Captures network level diagnostics.
  ///
  /// - Parameters:
  ///   - request: URL request.
  ///   - response: Optional URL response.
  ///   - data: Optional payload.
  ///   - error: Optional error.
  public static func captureNetworkLog(
    request: URLRequest,
    response: URLResponse?,
    data: Data?,
    error: Error?
  ) {
    var message = "Network \(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "unknown-url")"
    if let status = (response as? HTTPURLResponse)?.statusCode {
      message += " status=\(status)"
    }
    if let error {
      message += " error=\(error.localizedDescription)"
    }
    if let data, !data.isEmpty {
      message += " bytes=\(data.count)"
    }
    logger?.debug(message, metadata: ["source": "network"])
  }

  private static let signalHandler: @convention(c) (Int32) -> Void = { signalCode in
    let message = "Fatal signal received: \(signalCode)"
    logger?.error(message, metadata: ["source": "signal"])
    logger?.flushSynchronously()
    signal(signalCode, SIG_DFL)
    raise(signalCode)
  }

  fileprivate static func handleUncaughtException(_ exception: NSException) {
    let message = "Uncaught exception \(exception.name.rawValue): \(exception.reason ?? "No reason")\n\(exception.callStackSymbols.joined(separator: "\n"))"
    logger?.error(message, metadata: ["source": "uncaught_exception"])
    logger?.flushSynchronously()
  }
}
