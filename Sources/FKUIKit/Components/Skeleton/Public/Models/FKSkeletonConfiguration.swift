import UIKit

/// Appearance and motion defaults for skeleton placeholders (global, per-view, or per-block).
public struct FKSkeletonConfiguration: Sendable {

  // MARK: - Colors

  /// Base fill color of skeleton blocks.
  ///
  /// Defaults follow common light/dark placeholders: approximately `#F5F5F5` in light mode and `#333333` in dark mode.
  public var baseColor: UIColor

  /// Highlight mixed into shimmer or pulse animations.
  public var highlightColor: UIColor

  /// Optional three-stop palette for shimmer/pulse; defaults to `[base, highlight, base]` when `nil` or empty.
  public var gradientColors: [UIColor]?

  // MARK: - Shape

  /// Corner radius for blocks when ``inheritsCornerRadius`` is `false`.
  public var cornerRadius: CGFloat

  /// Stroke width drawn around the block fill using a darker tint of ``baseColor``.
  public var borderWidth: CGFloat

  /// When `true`, skeleton geometry follows the host view’s `layer.cornerRadius` (overlay and composable blocks).
  public var inheritsCornerRadius: Bool

  // MARK: - Animation

  /// Duration of one shimmer sweep or one pulse half-cycle, in seconds.
  public var animationDuration: TimeInterval

  /// Travel axis for shimmer; ignored unless ``animationMode`` is `.shimmer`.
  public var shimmerDirection: FKSkeletonShimmerDirection

  /// Motion style for the highlight band.
  public var animationMode: FKSkeletonAnimationMode

  /// Maps between coarse ``FKSkeletonStyle`` labels and ``animationMode``.
  public var style: FKSkeletonStyle {
    get {
      switch animationMode {
      case .none:
        return .solid
      case .shimmer:
        return .gradient
      case .pulse, .breathing:
        return .pulse
      }
    }
    set {
      switch newValue {
      case .solid:
        animationMode = .none
      case .gradient:
        animationMode = .shimmer
      case .pulse:
        animationMode = .pulse
      }
    }
  }

  /// Minimum gradient opacity during pulse/breathing (0…1).
  public var breathingMinOpacity: CGFloat

  // MARK: - Preset helpers (`FKSkeletonPresets`)

  /// Default line count for ``FKSkeletonPresets/textBlock(lineCount:configuration:)`` when `lineCount` is `nil`.
  public var defaultTextLineCount: Int

  /// Vertical gap between stacked preset lines.
  public var lineSpacing: CGFloat

  /// Height of each stacked line in text presets.
  public var lineHeight: CGFloat

  /// Horizontal spacing constant reserved for custom presets and builders.
  public var itemSpacing: CGFloat

  // MARK: - Transition

  /// Fade duration for ``FKSkeletonView`` show/hide and unified container dismiss.
  public var transitionDuration: TimeInterval

  // MARK: - Init

  public init(
    baseColor: UIColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        : UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
    },
    highlightColor: UIColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0.45, alpha: 1)
        : UIColor(white: 1, alpha: 1)
    },
    gradientColors: [UIColor]? = nil,
    cornerRadius: CGFloat = 6,
    borderWidth: CGFloat = 0,
    inheritsCornerRadius: Bool = true,
    animationDuration: TimeInterval = 1.4,
    shimmerDirection: FKSkeletonShimmerDirection = .leftToRight,
    animationMode: FKSkeletonAnimationMode = .shimmer,
    breathingMinOpacity: CGFloat = 0.45,
    defaultTextLineCount: Int = 4,
    lineSpacing: CGFloat = 8,
    lineHeight: CGFloat = 14,
    itemSpacing: CGFloat = 8,
    transitionDuration: TimeInterval = 0.25
  ) {
    self.baseColor = baseColor
    self.highlightColor = highlightColor
    self.gradientColors = gradientColors
    self.cornerRadius = max(0, cornerRadius)
    self.borderWidth = max(0, borderWidth)
    self.inheritsCornerRadius = inheritsCornerRadius
    self.animationDuration = max(0.1, animationDuration)
    self.shimmerDirection = shimmerDirection
    self.animationMode = animationMode
    self.breathingMinOpacity = min(1, max(0, breathingMinOpacity))
    self.defaultTextLineCount = max(1, defaultTextLineCount)
    self.lineSpacing = max(0, lineSpacing)
    self.lineHeight = max(1, lineHeight)
    self.itemSpacing = max(0, itemSpacing)
    self.transitionDuration = max(0, transitionDuration)
  }
}
