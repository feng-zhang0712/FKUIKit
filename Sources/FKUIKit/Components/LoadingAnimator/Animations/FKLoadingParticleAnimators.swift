//
// FKLoadingParticleAnimators.swift
//

import QuartzCore
import UIKit

/// Orbiting particle animator using `CAReplicatorLayer`.
///
/// A single dot source is replicated in polar layout, reducing CPU and memory overhead.
final class FKParticlesLoadingAnimator: FKLoadingBaseAnimator {
  /// Replicator that distributes particles around a circle.
  private let replicator = CAReplicatorLayer()
  /// Source particle layer used by the replicator.
  private let dotLayer = CALayer()

  /// Configures particle orbit geometry and appearance.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the animation.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)

    let count = max(3, style.particleCount)
    let radius = min(bounds.width, bounds.height) * 0.06
    let orbit = min(bounds.width, bounds.height) * 0.32

    replicator.frame = bounds
    replicator.instanceCount = count
    replicator.instanceTransform = CATransform3DMakeRotation((2 * .pi) / CGFloat(count), 0, 0, 1)
    replicator.instanceDelay = style.duration / Double(count)

    // Place the source dot on the top of the orbit; replicator rotates it around center.
    dotLayer.frame = CGRect(x: bounds.midX - radius, y: bounds.midY - orbit - radius, width: radius * 2, height: radius * 2)
    dotLayer.cornerRadius = radius
    dotLayer.backgroundColor = style.primaryColor.cgColor

    if dotLayer.superlayer == nil {
      replicator.addSublayer(dotLayer)
    }
    if replicator.superlayer == nil {
      renderLayer.addSublayer(replicator)
    }
  }

  /// Starts opacity cycling for replicated particles.
  override func start() {
    stop()

    // Replicator delay turns one opacity animation into a chasing particle effect.
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 1
    opacity.toValue = 0.2
    opacity.duration = style.duration / max(style.speed, 0.01)
    opacity.repeatCount = style.repeatCount
    opacity.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    dotLayer.add(opacity, forKey: "particles.opacity")
  }
}

/// Flowing particle animator using `CAEmitterLayer`.
///
/// Emits lightweight image-backed particles along the horizontal axis.
final class FKFlowingParticlesLoadingAnimator: FKLoadingBaseAnimator {
  /// Emitter layer responsible for particle generation.
  private let emitter = CAEmitterLayer()

  /// Configures emitter behavior and cell parameters.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for emission.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)

    emitter.frame = bounds
    emitter.emitterShape = .line
    emitter.emitterPosition = CGPoint(x: 0, y: bounds.midY)
    emitter.emitterSize = CGSize(width: 2, height: bounds.height * 0.5)
    emitter.renderMode = .additive

    // Use a compact SF Symbol image for particles to avoid custom texture assets.
    let cell = CAEmitterCell()
    cell.birthRate = Float(style.particleCount) * 2
    cell.lifetime = Float(style.duration * 1.5)
    cell.velocity = 56 * style.speed
    cell.velocityRange = 20
    cell.emissionLongitude = 0
    cell.emissionRange = .pi / 10
    cell.scale = 0.08
    cell.scaleRange = 0.04
    cell.alphaSpeed = -0.4
    cell.color = style.primaryColor.cgColor
    cell.contents = UIImage(systemName: "circle.fill")?.cgImage
    emitter.emitterCells = [cell]

    if emitter.superlayer == nil {
      renderLayer.addSublayer(emitter)
    }
  }

  /// Starts emission timeline by resetting begin time.
  override func start() {
    stop()
    emitter.beginTime = CACurrentMediaTime()
  }
}

/// Twinkling particle animator with replicated stars.
///
/// Produces a breathing "sparkle" effect through combined scale and opacity oscillation.
final class FKTwinkleParticlesLoadingAnimator: FKLoadingBaseAnimator {
  /// Replicates sparkle particles around a circular orbit.
  private let replicator = CAReplicatorLayer()
  /// Source sparkle layer used by the replicator.
  private let starLayer = CALayer()

  /// Configures twinkle particle layout.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the animation.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    let count = max(4, style.particleCount)
    let orbit = min(bounds.width, bounds.height) * 0.34
    let size = min(bounds.width, bounds.height) * 0.08

    replicator.frame = bounds
    replicator.instanceCount = count
    replicator.instanceTransform = CATransform3DMakeRotation((2 * .pi) / CGFloat(count), 0, 0, 1)
    replicator.instanceDelay = style.duration / Double(count)

    starLayer.frame = CGRect(x: bounds.midX - size / 2, y: bounds.midY - orbit - size / 2, width: size, height: size)
    starLayer.cornerRadius = size * 0.5
    starLayer.backgroundColor = style.secondaryColor.cgColor

    if starLayer.superlayer == nil {
      replicator.addSublayer(starLayer)
    }
    if replicator.superlayer == nil {
      renderLayer.addSublayer(replicator)
    }
  }

  /// Starts twinkle animations for scale and opacity.
  override func start() {
    stop()

    // Scale oscillation creates the sparkle "pop" effect.
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 0.3
    scale.toValue = 1.1
    scale.duration = style.duration / max(style.speed, 0.01)
    scale.repeatCount = style.repeatCount
    scale.autoreverses = true

    // Opacity oscillation complements scale for a natural twinkle.
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 0.2
    opacity.toValue = 1
    opacity.duration = scale.duration
    opacity.repeatCount = style.repeatCount
    opacity.autoreverses = true

    starLayer.add(scale, forKey: "twinkle.scale")
    starLayer.add(opacity, forKey: "twinkle.opacity")
  }
}
