/// Motion style for skeleton highlights.
public enum FKSkeletonAnimationMode: Sendable {
  /// Sliding gradient; one full sweep uses `FKSkeletonConfiguration.animationDuration`.
  case shimmer
  /// Opacity pulse on the highlight band.
  case pulse
  /// Same visual treatment as ``pulse`` (legacy alias).
  case breathing
  /// Static fill only.
  case none
}
