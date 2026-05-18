import Foundation

/// Parses LRC lyric files into timed lines.
public enum FKAudioLyricsParser {

  public enum ParserError: Error, Sendable {
    case invalidEncoding
  }

  public static func parse(data: Data) throws -> [FKAudioLyricLine] {
    guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) else {
      throw ParserError.invalidEncoding
    }
    return parse(content: content)
  }

  public static func parse(content: String) -> [FKAudioLyricLine] {
    var lines: [FKAudioLyricLine] = []
    let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

    for rawLine in content.components(separatedBy: .newlines) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      guard !line.isEmpty else { continue }
      let range = NSRange(line.startIndex..., in: line)
      guard let match = regex.firstMatch(in: line, range: range) else { continue }

      func substring(_ index: Int) -> String? {
        guard let swiftRange = Range(match.range(at: index), in: line) else { return nil }
        return String(line[swiftRange])
      }

      guard let minutes = substring(1).flatMap(Double.init),
            let seconds = substring(2).flatMap(Double.init) else { continue }
      let fraction = substring(3).flatMap(Double.init) ?? 0
      let millisDivisor: Double = (substring(3)?.count ?? 0) == 2 ? 100 : 1000
      let time = minutes * 60 + seconds + fraction / millisDivisor
      let text = substring(4)?.trimmingCharacters(in: .whitespaces) ?? ""
      guard !text.isEmpty else { continue }
      lines.append(FKAudioLyricLine(time: time, text: text))
    }

    return lines.sorted { $0.time < $1.time }
  }

  public static func activeLineIndex(at time: TimeInterval, in lines: [FKAudioLyricLine]) -> Int? {
    guard !lines.isEmpty else { return nil }
    var index: Int?
    for (offset, line) in lines.enumerated() where time >= line.time {
      index = offset
    }
    return index
  }
}
