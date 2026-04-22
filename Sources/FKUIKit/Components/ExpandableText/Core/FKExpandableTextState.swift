import Foundation

/// Represents the current expansion state of `FKExpandableText`.
///
/// Use this value in callbacks to react to user-driven or programmatic state changes.
/// The enum is lightweight and `Sendable`, making it safe to pass across concurrency
/// boundaries when coordinating UI-adjacent state in modern Swift code.
public enum FKExpandableTextState: Sendable, Equatable {
  /// Text is rendered in collapsed mode.
  case collapsed
  /// Text is rendered in expanded mode.
  case expanded
}
