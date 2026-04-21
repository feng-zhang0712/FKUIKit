import UIKit

/// Divider axis direction.
public enum FKDividerDirection: Int, Sendable {
  /// Horizontal divider.
  case horizontal
  /// Vertical divider.
  case vertical
}

/// Divider line style.
public enum FKDividerLineStyle: Int, Sendable {
  /// Solid line.
  case solid
  /// Dashed line.
  case dashed
}

/// Divider gradient orientation.
public enum FKDividerGradientDirection: Int, Sendable {
  /// Gradient flows from leading to trailing (or left to right in LTR coordinates).
  case horizontal
  /// Gradient flows from top to bottom.
  case vertical
}

/// Divider edge helper for auto-pinning into a container view.
public enum FKDividerPinnedEdge: Sendable {
  /// Pin to top edge.
  case top
  /// Pin to bottom edge.
  case bottom
  /// Pin to left edge.
  case left
  /// Pin to right edge.
  case right
}

/// Full configuration model for a divider instance.
public struct FKDividerConfiguration: @unchecked Sendable {
  /// Divider direction.
  public var direction: FKDividerDirection
  /// Divider style (`solid` or `dashed`).
  public var lineStyle: FKDividerLineStyle
  /// Logical thickness in points. Ignored when `isPixelPerfect` is `true`.
  public var thickness: CGFloat
  /// Divider color when gradient is disabled.
  public var color: UIColor
  /// Edge insets used to shorten the visible line segment inside bounds.
  public var contentInsets: UIEdgeInsets
  /// Enables 1-physical-pixel thickness adaptation (`1 / screenScale`).
  public var isPixelPerfect: Bool
  /// Dash pattern values (stroke length, gap length) for dashed style.
  public var dashPattern: [NSNumber]
  /// Enables gradient stroke rendering.
  public var showsGradient: Bool
  /// Gradient start color.
  public var gradientStartColor: UIColor
  /// Gradient end color.
  public var gradientEndColor: UIColor
  /// Gradient direction.
  public var gradientDirection: FKDividerGradientDirection

  /// Creates a divider configuration.
  ///
  /// - Parameters:
  ///   - direction: Divider direction.
  ///   - lineStyle: Divider style.
  ///   - thickness: Divider thickness in points.
  ///   - color: Divider color.
  ///   - contentInsets: Insets used to shorten the rendered stroke.
  ///   - isPixelPerfect: Whether to force 1-physical-pixel thickness.
  ///   - dashPattern: Dash pattern for dashed style.
  ///   - showsGradient: Whether gradient rendering is enabled.
  ///   - gradientStartColor: Gradient start color.
  ///   - gradientEndColor: Gradient end color.
  ///   - gradientDirection: Gradient direction.
  ///
  /// - Note: `thickness` is clamped to at least `0.5` points.
  public init(
    direction: FKDividerDirection = .horizontal,
    lineStyle: FKDividerLineStyle = .solid,
    thickness: CGFloat = 1,
    color: UIColor = .separator,
    contentInsets: UIEdgeInsets = .zero,
    isPixelPerfect: Bool = true,
    dashPattern: [NSNumber] = [4, 3],
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
}

/// Global manager for divider default configuration.
@MainActor
public final class FKDividerManager {
  /// Shared singleton.
  public static let shared = FKDividerManager()

  /// App-wide default configuration used by convenience APIs.
  ///
  /// New divider instances created via convenience paths can use this value as a baseline.
  public var defaultConfiguration = FKDividerConfiguration()

  private init() {}
}
