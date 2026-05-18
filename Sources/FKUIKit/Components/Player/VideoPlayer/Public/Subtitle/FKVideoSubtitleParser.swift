import Foundation

/// A single cue line for external subtitles.
public struct FKVideoSubtitleCue: Sendable, Equatable {
  public let start: TimeInterval
  public let end: TimeInterval
  public let text: String
}

/// Parses SRT and WebVTT subtitle files.
public enum FKVideoSubtitleParser {

  public static func parse(data: Data, format: FKVideoSubtitleFormat) throws -> [FKVideoSubtitleCue] {
    guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) else {
      throw FKVideoSubtitleParserError.invalidEncoding
    }
    switch format {
    case .srt:
      return parseSRT(content)
    case .vtt:
      return parseVTT(content)
    case .ass:
      return []
    }
  }

  public static func cue(at time: TimeInterval, in cues: [FKVideoSubtitleCue]) -> String? {
    cues.first { time >= $0.start && time <= $0.end }?.text
  }

  // MARK: - SRT

  private static func parseSRT(_ content: String) -> [FKVideoSubtitleCue] {
    let blocks = content.components(separatedBy: "\n\n")
    var cues: [FKVideoSubtitleCue] = []
    for block in blocks {
      let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
      guard lines.count >= 2 else { continue }
      let timeLineIndex = lines.firstIndex(where: { $0.contains("-->") }) ?? 1
      guard timeLineIndex < lines.count else { continue }
      let parts = lines[timeLineIndex].components(separatedBy: " --> ")
      guard parts.count == 2,
            let start = parseSRTTime(parts[0]),
            let end = parseSRTTime(parts[1]) else { continue }
      let text = lines.dropFirst(timeLineIndex + 1).joined(separator: "\n")
      guard !text.isEmpty else { continue }
      cues.append(FKVideoSubtitleCue(start: start, end: end, text: text))
    }
    return cues
  }

  private static func parseSRTTime(_ value: String) -> TimeInterval? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
    let parts = normalized.split(separator: ":")
    guard parts.count == 3, let seconds = Double(parts[2]) else { return nil }
    guard let minutes = Double(parts[1]), let hours = Double(parts[0]) else { return nil }
    return hours * 3600 + minutes * 60 + seconds
  }

  // MARK: - VTT

  private static func parseVTT(_ content: String) -> [FKVideoSubtitleCue] {
    var cues: [FKVideoSubtitleCue] = []
    let lines = content.components(separatedBy: .newlines)
    var index = 0
    while index < lines.count {
      let line = lines[index].trimmingCharacters(in: .whitespaces)
      if line.contains("-->") {
        let parts = line.components(separatedBy: " --> ")
        if parts.count == 2,
           let start = parseVTTTime(parts[0]),
           let end = parseVTTTime(parts[1].split(separator: " ").first.map(String.init) ?? parts[1]) {
          index += 1
          var textLines: [String] = []
          while index < lines.count, !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            textLines.append(lines[index])
            index += 1
          }
          let text = textLines.joined(separator: "\n")
          if !text.isEmpty {
            cues.append(FKVideoSubtitleCue(start: start, end: end, text: text))
          }
          continue
        }
      }
      index += 1
    }
    return cues
  }

  private static func parseVTTTime(_ value: String) -> TimeInterval? {
    let trimmed = value.trimmingCharacters(in: .whitespaces)
    let parts = trimmed.split(separator: ":")
    guard let last = parts.last, let seconds = Double(last) else { return nil }
    if parts.count == 2, let minutes = Double(parts[0]) {
      return minutes * 60 + seconds
    }
    if parts.count == 3,
       let minutes = Double(parts[1]),
       let hours = Double(parts[0]) {
      return hours * 3600 + minutes * 60 + seconds
    }
    return nil
  }
}

public enum FKVideoSubtitleParserError: Error {
  case invalidEncoding
}
