//
// FKExpandableTextState.swift
//
// State models for FKExpandableText.
//

import Foundation

/// Current display state of expandable text content.
public enum FKExpandableTextDisplayState: Hashable, Sendable {
  /// Text is rendered using collapsed line limit.
  case collapsed
  /// Text is rendered with unlimited lines.
  case expanded
}

/// Callback context when state changes.
public struct FKExpandableTextStateContext: Hashable, Sendable {
  /// New display state after the transition.
  public let state: FKExpandableTextDisplayState
  /// Whether the text content exceeds collapsed line limit.
  public let isTruncated: Bool
  /// Optional business identifier associated with this component instance.
  public let identifier: String?

  /// Creates callback context for expand/collapse events.
  ///
  /// - Parameters:
  ///   - state: New display state.
  ///   - isTruncated: Whether content is truncatable under current width and style.
  ///   - identifier: Optional state identifier used for reuse cache.
  public init(
    state: FKExpandableTextDisplayState,
    isTruncated: Bool,
    identifier: String?
  ) {
    self.state = state
    self.isTruncated = isTruncated
    self.identifier = identifier
  }
}
