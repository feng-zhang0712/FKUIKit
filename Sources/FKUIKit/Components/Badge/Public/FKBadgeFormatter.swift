import Foundation

/// Helpers for numeric badge strings and safe parsing from user or server input.
public enum FKBadgeFormatter {
  /// Formats a non-negative count using `maxDisplayCount` / `overflowSuffix`. Returns `nil` for values ≤ 0.
  ///
  /// - Parameters:
  ///   - count: Raw numeric value.
  ///   - configuration: Overflow-related configuration.
  /// - Returns: Display text or `nil` when the badge should be hidden in numeric mode.
  public static func displayString(count: Int, configuration: FKBadgeConfiguration) -> String? {
    guard count > 0 else { return nil }
    if count <= configuration.maxDisplayCount {
      return String(count)
    }
    return "\(configuration.maxDisplayCount)\(configuration.overflowSuffix)"
  }

  /// Parses a string of decimal digits; rejects non-numeric junk and negatives.
  ///
  /// - Parameter string: Raw external input string.
  /// - Returns: Parsed non-negative integer, or `nil` when invalid.
  public static func parseNonNegativeCount(_ string: String) -> Int? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard trimmed.allSatisfy({ $0.isNumber }) else { return nil }
    guard let value = Int(trimmed), value >= 0 else { return nil }
    return value
  }
}
