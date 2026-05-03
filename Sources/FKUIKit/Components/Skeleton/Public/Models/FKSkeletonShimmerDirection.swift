import Foundation

/// Direction of the shimmer highlight sweep across skeleton blocks.
public enum FKSkeletonShimmerDirection: Sendable {
  case leftToRight
  case rightToLeft
  case topToBottom
  case bottomToTop
  /// Diagonal sweep from top-leading toward bottom-trailing.
  case diagonal
}
