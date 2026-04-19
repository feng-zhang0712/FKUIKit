//
// FKBadgeVisibility.swift
//

import Foundation

/// Overrides automatic visibility (for example global “do not disturb” or marketing overlays).
public enum FKBadgeVisibilityPolicy: Sendable, Equatable {
  /// Hide when content is empty, count ≤ 0, or invalid numeric input.
  case automatic
  /// Always hidden regardless of content.
  case forcedHidden
  /// Always visible when there is drawable content (dot / text). Count 0 still hides unless you show a dot or text explicitly.
  case forcedVisible
}
