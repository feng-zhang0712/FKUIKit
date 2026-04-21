import Foundation

/// Default formatter used by `FKLogger`.
public struct FKLogFormatter: FKLogFormatting {
  private final class DateFormatterBox: @unchecked Sendable {
    let formatter: DateFormatter

    init() {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      self.formatter = formatter
    }
  }

  private let dateFormatterBox = DateFormatterBox()
  private let dateQueue = DispatchQueue(label: "com.fkkit.logger.formatter.date")

  /// Creates default formatter.
  public init() {}

  /// Formats one event with current config switches.
  public func format(event: FKLogEvent, config: FKLoggerConfig) -> String {
    var parts: [String] = []
    parts.reserveCapacity(8)

    if !config.prefix.isEmpty {
      parts.append(config.prefix)
    }

    if config.includesTimestamp {
      parts.append("[\(timestampString(from: event.timestamp))]")
    }

    if config.usesEmoji {
      parts.append(event.level.emoji)
    }

    parts.append("[\(event.level.label)]")

    var sourceParts: [String] = []
    if config.includesFileName {
      sourceParts.append(trimmedFileName(from: event.file))
    }
    if config.includesFunctionName {
      sourceParts.append(event.function)
    }
    if config.includesLineNumber {
      sourceParts.append("#\(event.line)")
    }
    if !sourceParts.isEmpty {
      parts.append("{\(sourceParts.joined(separator: ":"))}")
    }

    parts.append(event.message)

    if !event.metadata.isEmpty {
      let metadataText = event.metadata
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: ", ")
      parts.append("|\(metadataText)|")
    }

    return parts.joined(separator: " ")
  }

  private func timestampString(from date: Date) -> String {
    dateQueue.sync {
      dateFormatterBox.formatter.string(from: date)
    }
  }

  private func trimmedFileName(from filePath: String) -> String {
    URL(fileURLWithPath: filePath).lastPathComponent
  }
}
