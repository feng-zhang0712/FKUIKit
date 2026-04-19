//
// FKNetworkLogger.swift
//

import Foundation
import os.log

final class FKNetworkLogger: Sendable {

  private let logLevel: FKNetworkLogLevel
  private let logger = Logger(subsystem: "FKNetwork", category: "HTTP")

  init(logLevel: FKNetworkLogLevel) {
    self.logLevel = logLevel
  }

  func logRequest(_ request: URLRequest) {
    guard logLevel >= .info else { return }
    var lines = ["→ \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "")"]
    if logLevel >= .verbose {
      request.allHTTPHeaderFields?.forEach { lines.append("  Header: \($0.key): \($0.value)") }
      if let body = request.httpBody, let str = String(data: body, encoding: .utf8) {
        lines.append("  Body: \(str)")
      }
    }
    logger.debug("\(lines.joined(separator: "\n"))")
  }

  func logResponse(_ response: URLResponse?, data: Data?, error: Error?, duration: TimeInterval) {
    guard logLevel >= .info else { return }
    if let error {
      guard logLevel >= .error else { return }
      logger.error("✗ Error (\(String(format: "%.2f", duration))s): \(error.localizedDescription)")
      return
    }
    guard let http = response as? HTTPURLResponse else { return }
    let symbol = (200..<300).contains(http.statusCode) ? "✓" : "✗"
    var lines = ["\(symbol) \(http.statusCode) (\(String(format: "%.2f", duration))s) \(http.url?.absoluteString ?? "")"]
    if logLevel >= .verbose, let data, let str = String(data: data, encoding: .utf8) {
      let preview = str.count > 500 ? String(str.prefix(500)) + "…" : str
      lines.append("  Response: \(preview)")
    }
    logger.debug("\(lines.joined(separator: "\n"))")
  }
}
