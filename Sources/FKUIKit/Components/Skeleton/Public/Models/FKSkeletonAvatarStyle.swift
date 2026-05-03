import CoreGraphics

/// Avatar silhouette for ``FKSkeletonPresets/listRow(avatarStyle:)``.
public enum FKSkeletonAvatarStyle: Sendable {
  case circle
  case rounded(cornerRadius: CGFloat)
}
