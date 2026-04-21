//
// FKSkeletonShape.swift
//

import CoreGraphics

/// Shape strategy used by one skeleton placeholder.
public enum FKSkeletonShape: Sendable, Equatable {
  /// Rectangle with no corner radius.
  case rectangle
  /// Circle based on the shortest side.
  case circle
  /// Rounded rectangle using the global `cornerRadius`.
  case rounded
  /// Rounded rectangle using a custom radius.
  case custom(CGFloat)
}
