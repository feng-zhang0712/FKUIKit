import UIKit

/// Runtime context passed to custom FK transition animator factories.
public struct FKAnimationContext {
  /// Whether this transition is a presentation.
  public let isPresentation: Bool
  /// Presentation layout being animated.
  public let layout: FKPresentationConfiguration.Layout
  /// View being animated.
  public let animatingView: UIView
  /// Start frame prepared by FK.
  public let startFrame: CGRect
  /// End frame prepared by FK.
  public let endFrame: CGRect
}

/// Configuration describing built-in or fully custom transition animations.
public struct FKAnimationConfiguration {
  /// Selected built-in animation preset.
  public var preset: FKAnimationPreset
  /// Duration used by built-in presets.
  public var duration: TimeInterval
  /// Spring damping ratio used by `.spring` / `.systemLike`.
  public var dampingRatio: CGFloat
  /// Approximate spring response (higher means quicker settle).
  public var response: CGFloat
  /// Optional custom cubic timing parameters for non-spring presets.
  public var timingCurve: UICubicTimingParameters?
  /// Optional custom property animator factory. Returning non-nil overrides built-in presets.
  ///
  /// - Important: Capture external owners weakly (`[weak self]`) when referencing view controllers
  ///   to avoid retain cycles during transition storage and callbacks.
  public var customPropertyAnimator: ((FKAnimationContext) -> UIViewPropertyAnimator?)?
  /// Optional custom animator provider that replaces FK animator objects entirely.
  public var customAnimatorProvider: (any FKPresentationAnimatorProviding)?

  /// Creates animation configuration with useful defaults.
  public init(
    preset: FKAnimationPreset = .systemLike,
    duration: TimeInterval = 0.32,
    dampingRatio: CGFloat = 0.9,
    response: CGFloat = 0.45,
    timingCurve: UICubicTimingParameters? = nil,
    customPropertyAnimator: ((FKAnimationContext) -> UIViewPropertyAnimator?)? = nil,
    customAnimatorProvider: (any FKPresentationAnimatorProviding)? = nil
  ) {
    self.preset = preset
    self.duration = max(0, duration)
    self.dampingRatio = min(max(dampingRatio, 0.1), 1)
    self.response = max(0.1, response)
    self.timingCurve = timingCurve
    self.customPropertyAnimator = customPropertyAnimator
    self.customAnimatorProvider = customAnimatorProvider
  }
}

