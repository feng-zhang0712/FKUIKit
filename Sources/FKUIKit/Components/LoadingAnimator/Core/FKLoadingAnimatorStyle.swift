//
// FKLoadingAnimatorStyle.swift
//

import UIKit

/// Built-in and custom animation styles.
public enum FKLoadingAnimatorStyle {
  /// Rotating circular stroke with animated head/tail.
  case ring
  /// Rotating ring masked by a gradient layer.
  case gradientRing
  /// Determinate ring that reflects explicit progress updates.
  case progressRing
  /// Single flowing sine wave path animation.
  case wave
  /// Expanding ripple circles based on replicated pulses.
  case rippleWave
  /// Circular particle matrix with fading dots.
  case particles
  /// Horizontal flowing emitter particles.
  case flowingParticles
  /// Twinkling particles distributed around an orbit.
  case twinkleParticles
  /// Enhanced system indicator backed by `UIActivityIndicatorView`.
  case spinner
  /// Circular breathing pulse animation.
  case pulseCircle
  /// Square breathing pulse animation.
  case pulseSquare
  /// Rotating-dots style using replicator timing offsets.
  case rotatingDots
  /// Gear-shaped outline rotation animation.
  case gear
  /// Custom animator implementation for extension scenarios.
  ///
  /// - Parameter FKLoadingAnimationProviding: User-provided animator object.
  case custom(FKLoadingAnimationProviding)
}

/// Style values used by all animators.
public struct FKLoadingAnimatorStyleConfiguration {
  /// Primary style color used by most layers. Default is `.systemBlue`.
  public var primaryColor: UIColor
  /// Secondary accent color for dual-color styles. Default is `.systemTeal`.
  public var secondaryColor: UIColor
  /// Gradient color stops for gradient-based styles.
  public var gradientColors: [UIColor]
  /// Generic stroke width for line-based animations. Default is `3`.
  public var lineWidth: CGFloat
  /// Corner radius for animator container or rounded shapes. Default is `12`.
  public var cornerRadius: CGFloat
  /// Global speed multiplier. Values greater than `1` run faster.
  public var speed: CGFloat
  /// Animation repeat count. Use `.infinity` for continuous loading.
  public var repeatCount: Float
  /// Base duration in seconds for one animation cycle. Default is `1.2`.
  public var duration: CFTimeInterval
  /// Number of particles for particle-based styles. Minimum effective value is `1`.
  public var particleCount: Int
  /// Vertical wave amplitude in points for wave styles.
  public var waveAmplitude: CGFloat
  /// Stroke width dedicated to ring-based styles.
  public var ringWidth: CGFloat

  /// Creates a style configuration shared by all built-in animators.
  ///
  /// - Parameters:
  ///   - primaryColor: Main drawing color.
  ///   - secondaryColor: Auxiliary drawing color.
  ///   - gradientColors: Gradient stop colors for gradient ring styles.
  ///   - lineWidth: Default line width for stroked paths.
  ///   - cornerRadius: Rounded corner value for container or shape usage.
  ///   - speed: Playback speed multiplier (`> 0` recommended).
  ///   - repeatCount: Number of animation repeats.
  ///   - duration: Base cycle duration in seconds.
  ///   - particleCount: Particle amount for particle styles.
  ///   - waveAmplitude: Wave amplitude in points.
  ///   - ringWidth: Dedicated line width for ring styles.
  public init(
    primaryColor: UIColor = .systemBlue,
    secondaryColor: UIColor = .systemTeal,
    gradientColors: [UIColor] = [.systemBlue, .systemTeal, .systemPurple],
    lineWidth: CGFloat = 3,
    cornerRadius: CGFloat = 12,
    speed: CGFloat = 1,
    repeatCount: Float = .infinity,
    duration: CFTimeInterval = 1.2,
    particleCount: Int = 8,
    waveAmplitude: CGFloat = 8,
    ringWidth: CGFloat = 4
  ) {
    self.primaryColor = primaryColor
    self.secondaryColor = secondaryColor
    self.gradientColors = gradientColors
    self.lineWidth = lineWidth
    self.cornerRadius = cornerRadius
    self.speed = speed
    self.repeatCount = repeatCount
    self.duration = duration
    self.particleCount = max(1, particleCount)
    self.waveAmplitude = waveAmplitude
    self.ringWidth = ringWidth
  }
}

/// Presentation mode for loading UI.
public enum FKLoadingAnimatorPresentationMode: Equatable {
  /// Displays the animator inside the host view hierarchy.
  case embedded
  /// Displays a full-screen-style mask overlay with centered animator.
  case fullScreen
}
