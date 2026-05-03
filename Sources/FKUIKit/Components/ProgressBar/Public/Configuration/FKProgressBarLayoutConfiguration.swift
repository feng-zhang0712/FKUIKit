import UIKit

/// Geometry for ``FKProgressBar``: variant, axis, track/ring sizing, insets, and linear segmentation.
///
/// - Note: Marked `@unchecked Sendable` because `UIColor` is not `Sendable`; treat as main-thread snapshots.
public struct FKProgressBarLayoutConfiguration: @unchecked Sendable {
  public var variant: FKProgressBarVariant
  public var axis: FKProgressBarAxis

  /// Linear track thickness (height for horizontal, width for vertical).
  public var trackThickness: CGFloat
  /// Corner radius for the linear track; `nil` uses half of `trackThickness` (capsule).
  public var trackCornerRadius: CGFloat?

  /// Ring stroke width (``FKProgressBarVariant/ring``).
  public var ringLineWidth: CGFloat
  /// Total diameter of the ring including stroke; `nil` uses intrinsic default (36 pt).
  public var ringDiameter: CGFloat?

  /// Insets applied inside the view bounds before laying out track / ring / label.
  public var contentInsets: UIEdgeInsets

  public var linearCapStyle: FKProgressBarLinearCapStyle
  /// When `> 1`, draws a segmented track (visual chunks); `0` or `1` is a continuous bar.
  public var segmentCount: Int
  /// Gap between segments as a fraction of segment width (clamped).
  public var segmentGapFraction: CGFloat

  public init(
    variant: FKProgressBarVariant = .linear,
    axis: FKProgressBarAxis = .horizontal,
    trackThickness: CGFloat = 4,
    trackCornerRadius: CGFloat? = nil,
    ringLineWidth: CGFloat = 4,
    ringDiameter: CGFloat? = nil,
    contentInsets: UIEdgeInsets = .zero,
    linearCapStyle: FKProgressBarLinearCapStyle = .round,
    segmentCount: Int = 0,
    segmentGapFraction: CGFloat = 0.08
  ) {
    self.variant = variant
    self.axis = axis
    self.trackThickness = max(0.5, trackThickness)
    self.trackCornerRadius = trackCornerRadius
    self.ringLineWidth = max(0.5, ringLineWidth)
    self.ringDiameter = ringDiameter.map { max(8, $0) }
    self.contentInsets = contentInsets
    self.linearCapStyle = linearCapStyle
    self.segmentCount = max(0, segmentCount)
    self.segmentGapFraction = min(max(0, segmentGapFraction), 0.45)
  }
}
