import UIKit

// MARK: - Axis & style

/// Divider axis.
public enum FKDividerDirection: Int, Sendable {
  /// Horizontal line (typical row separator).
  case horizontal
  /// Vertical line (column separator).
  case vertical
}

/// Solid or dashed stroke.
public enum FKDividerLineStyle: Int, Sendable {
  case solid
  case dashed
}

/// Gradient axis when `showsGradient` is enabled. Horizontal case follows **leading → trailing** (RTL-aware in SwiftUI; UIKit flips `CAGradientLayer` under RTL).
public enum FKDividerGradientDirection: Int, Sendable {
  case horizontal
  case vertical
}

/// Edge used by `UIView.fk_addDivider(at:…)` to pin a divider inside a container using Auto Layout.
public enum FKDividerPinnedEdge: Sendable {
  case top
  case bottom
  /// Pins to the **leading** edge (maps to `leadingAnchor`).
  case leading
  /// Pins to the **trailing** edge (maps to `trailingAnchor`).
  case trailing
}

// MARK: - Configuration

/// Visual parameters for `FKDivider` / `FKDividerView`.
///
/// - Note: Marked `@unchecked Sendable` because `UIColor` is not `Sendable`; treat instances as main-thread configuration snapshots.
public struct FKDividerConfiguration: @unchecked Sendable {
  public var direction: FKDividerDirection
  public var lineStyle: FKDividerLineStyle
  /// Logical thickness in points; ignored when `isPixelPerfect` is `true`.
  public var thickness: CGFloat
  /// Color used when `showsGradient` is `false`.
  public var color: UIColor
  /// Insets that shorten the stroke inside the view bounds (UIKit coordinates: left/right for horizontal, top/bottom for vertical).
  public var contentInsets: UIEdgeInsets
  /// When `true`, stroke thickness is `1 / displayScale` (hairline).
  public var isPixelPerfect: Bool
  /// Dash lengths in **points** for `.dashed` (alternating drawn gap, drawn gap, …). At least two values are typical; shorter arrays are padded when applied to `CAShapeLayer`.
  public var dashPattern: [CGFloat]
  public var showsGradient: Bool
  public var gradientStartColor: UIColor
  public var gradientEndColor: UIColor
  public var gradientDirection: FKDividerGradientDirection

  /// Creates a configuration. `thickness` is clamped to at least `0.5` pt when not pixel-perfect.
  public init(
    direction: FKDividerDirection = .horizontal,
    lineStyle: FKDividerLineStyle = .solid,
    thickness: CGFloat = 1,
    color: UIColor = .separator,
    contentInsets: UIEdgeInsets = .zero,
    isPixelPerfect: Bool = true,
    dashPattern: [CGFloat] = [4, 3],
    showsGradient: Bool = false,
    gradientStartColor: UIColor = .systemBlue,
    gradientEndColor: UIColor = .systemTeal,
    gradientDirection: FKDividerGradientDirection = .horizontal
  ) {
    self.direction = direction
    self.lineStyle = lineStyle
    self.thickness = max(0.5, thickness)
    self.color = color
    self.contentInsets = contentInsets
    self.isPixelPerfect = isPixelPerfect
    self.dashPattern = dashPattern
    self.showsGradient = showsGradient
    self.gradientStartColor = gradientStartColor
    self.gradientEndColor = gradientEndColor
    self.gradientDirection = gradientDirection
  }

  /// Pattern suitable for `CAShapeLayer.lineDashPattern` (minimum two numbers).
  func dashPatternNumbers() -> [NSNumber] {
    let values: [CGFloat]
    if dashPattern.count >= 2 {
      values = dashPattern
    } else if let first = dashPattern.first {
      values = [first, first]
    } else {
      values = [4, 3]
    }
    return values.map { NSNumber(value: Double(max(0.01, $0))) }
  }
}
