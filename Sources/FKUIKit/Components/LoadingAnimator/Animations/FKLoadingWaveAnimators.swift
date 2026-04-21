//
// FKLoadingWaveAnimators.swift
//

import QuartzCore
import UIKit

/// Sine-wave loading animator.
///
/// Animates a stroked `CAShapeLayer.path` through precomputed phases.
final class FKWaveLoadingAnimator: FKLoadingBaseAnimator {
  /// Shape layer used to render the wave line.
  private let waveLayer = CAShapeLayer()

  /// Configures wave appearance and initial path.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the wave.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    waveLayer.frame = bounds
    waveLayer.fillColor = UIColor.clear.cgColor
    waveLayer.strokeColor = style.primaryColor.cgColor
    waveLayer.lineWidth = style.lineWidth
    waveLayer.lineCap = .round
    waveLayer.path = wavePath(phase: 0).cgPath
    if waveLayer.superlayer == nil {
      renderLayer.addSublayer(waveLayer)
    }
  }

  /// Starts wave path interpolation animation.
  override func start() {
    stop()
    // Keyframe over multiple phase offsets yields smooth wave flow without per-frame CPU path generation.
    let phase = CAKeyframeAnimation(keyPath: "path")
    phase.values = stride(from: 0, through: Double.pi * 2, by: Double.pi / 8).map {
      wavePath(phase: CGFloat($0)).cgPath
    }
    phase.duration = style.duration / max(style.speed, 0.01)
    phase.repeatCount = style.repeatCount
    phase.calculationMode = .linear
    waveLayer.add(phase, forKey: "wave.path")
  }

  /// Builds a sine-wave bezier path for a specific phase.
  ///
  /// - Parameter phase: Phase offset in radians.
  /// - Returns: A bezier path representing the sampled wave line.
  private func wavePath(phase: CGFloat) -> UIBezierPath {
    let path = UIBezierPath()
    let width = bounds.width
    let height = bounds.height
    let mid = height * 0.5
    let amplitude = min(style.waveAmplitude, height * 0.35)
    path.move(to: CGPoint(x: 0, y: mid))
    // Sampling every 2pt balances visual smoothness and path complexity.
    for x in stride(from: CGFloat.zero, through: width, by: 2) {
      let y = mid + sin((x / width) * .pi * 2 + phase) * amplitude
      path.addLine(to: CGPoint(x: x, y: y))
    }
    return path
  }
}

/// Ripple-wave animator based on replicated pulse layers.
///
/// `CAReplicatorLayer` duplicates one pulse source with time offsets, minimizing layer count.
final class FKRippleWaveLoadingAnimator: FKLoadingBaseAnimator {
  /// Replicates ripple instances with temporal offsets.
  private let replicator = CAReplicatorLayer()
  /// Source pulse layer replicated by `replicator`.
  private let dot = CAShapeLayer()

  /// Configures ripple source and replication timing.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the ripple.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    replicator.frame = bounds
    replicator.instanceCount = 3
    replicator.instanceDelay = style.duration / 3

    let radius = min(bounds.width, bounds.height) * 0.12
    dot.path = UIBezierPath(ovalIn: CGRect(x: bounds.midX - radius, y: bounds.midY - radius, width: radius * 2, height: radius * 2)).cgPath
    dot.fillColor = style.primaryColor.cgColor
    dot.opacity = 0

    if dot.superlayer == nil {
      replicator.addSublayer(dot)
    }
    if replicator.superlayer == nil {
      renderLayer.addSublayer(replicator)
    }
  }

  /// Starts ripple scale and fade animations.
  override func start() {
    stop()

    // Scale expansion creates outward ripple propagation.
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 0.3
    scale.toValue = 2.6
    scale.duration = style.duration / max(style.speed, 0.01)
    scale.repeatCount = style.repeatCount
    scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

    // Opacity fade keeps ripple exit smooth and avoids hard clipping edges.
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 0.8
    opacity.toValue = 0
    opacity.duration = scale.duration
    opacity.repeatCount = style.repeatCount
    opacity.timingFunction = CAMediaTimingFunction(name: .easeOut)

    dot.add(scale, forKey: "ripple.scale")
    dot.add(opacity, forKey: "ripple.opacity")
  }
}
