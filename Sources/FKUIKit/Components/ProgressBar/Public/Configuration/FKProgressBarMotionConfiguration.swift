import UIKit

/// Determinate animation timing, indeterminate visuals, reduced motion, and completion haptics.
public struct FKProgressBarMotionConfiguration: Sendable {
  public var animationDuration: TimeInterval
  public var timing: FKProgressBarTiming
  /// When `true`, uses `UIView.animate` spring for determinate changes instead of `CAMediaTimingFunction`.
  public var prefersSpringAnimation: Bool
  public var springDampingRatio: CGFloat
  public var springVelocity: CGFloat

  public var indeterminateStyle: FKProgressBarIndeterminateStyle
  /// One full marquee cycle duration (linear) or pulse period (breathing).
  public var indeterminatePeriod: TimeInterval
  /// When `false`, ``FKProgressBar/isIndeterminate`` still drives label and accessibility, but marquee / breathing / ring rotation are not animated (static indeterminate look).
  public var playsIndeterminateAnimation: Bool

  public var respectsReducedMotion: Bool
  public var completionHaptic: FKProgressBarCompletionHaptic

  public init(
    animationDuration: TimeInterval = 0.25,
    timing: FKProgressBarTiming = .default,
    prefersSpringAnimation: Bool = false,
    springDampingRatio: CGFloat = 0.82,
    springVelocity: CGFloat = 0.35,
    indeterminateStyle: FKProgressBarIndeterminateStyle = .marquee,
    indeterminatePeriod: TimeInterval = 1.35,
    playsIndeterminateAnimation: Bool = true,
    respectsReducedMotion: Bool = true,
    completionHaptic: FKProgressBarCompletionHaptic = .none
  ) {
    self.animationDuration = max(0, animationDuration)
    self.timing = timing
    self.prefersSpringAnimation = prefersSpringAnimation
    self.springDampingRatio = min(max(0.01, springDampingRatio), 1.2)
    self.springVelocity = springVelocity
    self.indeterminateStyle = indeterminateStyle
    self.indeterminatePeriod = max(0.2, indeterminatePeriod)
    self.playsIndeterminateAnimation = playsIndeterminateAnimation
    self.respectsReducedMotion = respectsReducedMotion
    self.completionHaptic = completionHaptic
  }
}
