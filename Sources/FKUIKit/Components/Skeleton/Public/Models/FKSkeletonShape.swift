import CoreGraphics

/// Corner strategy for auto-generated placeholders on a specific view.
public enum FKSkeletonShape: Sendable, Equatable {
  case rectangle
  case circle
  case rounded
  case custom(CGFloat)
}
