//
// FKLoadingAnimatorFactory.swift
//

import Foundation

/// Factory responsible for mapping style enums to concrete animator implementations.
///
/// Centralizing this mapping keeps `FKLoadingAnimatorView` decoupled from individual animator types.
enum FKLoadingAnimatorFactory {
  /// Creates an animator instance for the given style.
  ///
  /// - Parameter style: Desired loading style.
  /// - Returns: A concrete `FKLoadingAnimationProviding` implementation.
  @MainActor
  static func makeAnimator(style: FKLoadingAnimatorStyle) -> FKLoadingAnimationProviding {
    switch style {
    case .ring:
      return FKRingLoadingAnimator()
    case .gradientRing:
      return FKGradientRingLoadingAnimator()
    case .progressRing:
      return FKProgressRingLoadingAnimator()
    case .wave:
      return FKWaveLoadingAnimator()
    case .rippleWave:
      return FKRippleWaveLoadingAnimator()
    case .particles:
      return FKParticlesLoadingAnimator()
    case .flowingParticles:
      return FKFlowingParticlesLoadingAnimator()
    case .twinkleParticles:
      return FKTwinkleParticlesLoadingAnimator()
    case .spinner:
      return FKSpinnerLoadingAnimator()
    case .pulseCircle:
      return FKPulseLoadingAnimator(isSquare: false)
    case .pulseSquare:
      return FKPulseLoadingAnimator(isSquare: true)
    case .rotatingDots:
      return FKRotatingDotsLoadingAnimator()
    case .gear:
      return FKGearLoadingAnimator()
    case let .custom(animator):
      return animator
    }
  }
}
