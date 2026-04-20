//
// FKBadgeFormatter.swift
//

import Foundation

/// Helpers for numeric badge strings and safe parsing from user or server input.
public enum FKBadgeFormatter {
  /// Formats a non-negative count using `maxDisplayCount` / `overflowSuffix`. Returns `nil` for values ≤ 0.
  public static func displayString(count: Int, configuration: FKBadgeConfiguration) -> String? {
    guard count > 0 else { return nil }
    if count <= configuration.maxDisplayCount {
      return String(count)
    }
    return "\(configuration.maxDisplayCount)\(configuration.overflowSuffix)"
  }

  /// Parses a decimal string; rejects non-numeric junk and negatives.
  public static func parseNonNegativeCount(_ string: String) -> Int? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard trimmed.allSatisfy({ $0.isNumber }) else { return nil }
    guard let value = Int(trimmed), value >= 0 else { return nil }
    return value
  }
}
