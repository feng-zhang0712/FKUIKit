//
// FKSkeletonConfiguration.swift
//

import UIKit

/// Global and per-instance configuration for skeleton appearance and animation.
public struct FKSkeletonConfiguration: Sendable {

  // MARK: - Colors

  /// Base fill color of skeleton blocks.
  ///
  /// Defaults follow common light/dark placeholders: `#F5F5F5` in light mode, `#333333` in dark mode.
  public var baseColor: UIColor

  /// Highlight color swept across during shimmer, or mixed for breathing.
  public var highlightColor: UIColor

  // MARK: - Shape

  /// Default corner radius applied to skeleton blocks when `inheritsCornerRadius` is `false`.
  public var cornerRadius: CGFloat

  /// When `true`, skeleton blocks inherit the host view's `layer.cornerRadius`.
  public var inheritsCornerRadius: Bool

  // MARK: - Animation

  /// Duration of one full shimmer sweep, or one full breathing cycle (seconds).
  public var animationDuration: TimeInterval

  /// Direction the shimmer gradient travels (ignored for `breathing` / `none`).
  public var shimmerDirection: FKSkeletonShimmerDirection

  /// Active animation style.
  public var animationMode: FKSkeletonAnimationMode

  /// Minimum opacity of the highlight during breathing (0…1).
  public var breathingMinOpacity: CGFloat

  // MARK: - Preset defaults (text / list factories)

  /// Default number of text lines for `FKSkeletonPresets.textBlock` when not overridden per call.
  public var defaultTextLineCount: Int

  /// Default vertical gap between stacked line blocks in presets.
  public var lineSpacing: CGFloat

  /// Default height of a single text line block in presets.
  public var lineHeight: CGFloat

  // MARK: - Transition

  /// Duration of the show/hide fade transition.
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
    cornerRadius: CGFloat = 6,
    inheritsCornerRadius: Bool = true,
    animationDuration: TimeInterval = 1.4,
    shimmerDirection: FKSkeletonShimmerDirection = .leftToRight,
    animationMode: FKSkeletonAnimationMode = .shimmer,
    breathingMinOpacity: CGFloat = 0.45,
    defaultTextLineCount: Int = 4,
    lineSpacing: CGFloat = 8,
    lineHeight: CGFloat = 14,
    transitionDuration: TimeInterval = 0.25
  ) {
    self.baseColor = baseColor
    self.highlightColor = highlightColor
    self.cornerRadius = max(0, cornerRadius)
    self.inheritsCornerRadius = inheritsCornerRadius
    self.animationDuration = max(0.1, animationDuration)
    self.shimmerDirection = shimmerDirection
    self.animationMode = animationMode
    self.breathingMinOpacity = min(1, max(0, breathingMinOpacity))
    self.defaultTextLineCount = max(1, defaultTextLineCount)
    self.lineSpacing = max(0, lineSpacing)
    self.lineHeight = max(1, lineHeight)
    self.transitionDuration = max(0, transitionDuration)
  }
}

// MARK: - Shimmer direction

/// The direction the shimmer highlight sweeps across skeleton blocks.
public enum FKSkeletonShimmerDirection: Sendable {
  case leftToRight
  case rightToLeft
  case topToBottom
  case bottomToTop
  /// Diagonal sweep from top-leading to bottom-trailing.
  case diagonal
}
