//
// FKSkeletonAnimationMode.swift
//

/// How skeleton blocks animate their highlight.
public enum FKSkeletonAnimationMode: Sendable {
  /// Sliding gradient (shimmer), one sweep per `animationDuration`.
  case shimmer
  /// Soft bright/dark pulse on the highlight band.
  case breathing
  /// Static fill only (no motion).
  case none
}
