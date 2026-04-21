//
// FKLoadingRingAnimators.swift
//

import QuartzCore
import UIKit

/// Circular indeterminate ring animator.
///
/// Uses a single `CAShapeLayer` with rotation and stroke animations for low-overhead rendering.
final class FKRingLoadingAnimator: FKLoadingBaseAnimator {
  /// Shape layer that draws the visible ring stroke.
  private let ringLayer = CAShapeLayer()

  /// Configures ring geometry and visual style.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the ring.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    // Keep all drawing in a single shape layer to avoid extra compositing work.
    ringLayer.frame = bounds
    ringLayer.fillColor = UIColor.clear.cgColor
    ringLayer.strokeColor = style.primaryColor.cgColor
    ringLayer.lineWidth = style.ringWidth
    ringLayer.lineCap = .round
    // Draw one full circle path and animate stroke/rotation instead of rebuilding geometry every frame.
    ringLayer.path = UIBezierPath(
      arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
      radius: min(bounds.width, bounds.height) * 0.36,
      startAngle: -.pi / 2,
      endAngle: .pi * 1.5,
      clockwise: true
    ).cgPath
    if ringLayer.superlayer == nil {
      renderLayer.addSublayer(ringLayer)
    }
  }

  /// Starts indeterminate ring animations.
  ///
  /// Rotation and stroke-end timelines are separated so the ring feels dynamic while remaining GPU-friendly.
  override func start() {
    stop()

    // Continuous z-rotation drives global motion.
    let spin = CABasicAnimation(keyPath: "transform.rotation.z")
    spin.fromValue = 0
    spin.toValue = Double.pi * 2
    spin.duration = style.duration / max(style.speed, 0.01)
    spin.repeatCount = style.repeatCount
    spin.timingFunction = CAMediaTimingFunction(name: .linear)
    ringLayer.add(spin, forKey: "spin")

    // Stroke-end breathing simulates the classic loading arc expansion/contraction.
    let stroke = CABasicAnimation(keyPath: "strokeEnd")
    stroke.fromValue = 0.2
    stroke.toValue = 1
    stroke.autoreverses = true
    stroke.duration = style.duration * 0.7
    stroke.repeatCount = style.repeatCount
    ringLayer.add(stroke, forKey: "stroke")
  }
}

/// Gradient circular ring animator.
///
/// Renders a `CAGradientLayer` masked by a ring-shaped `CAShapeLayer`.
final class FKGradientRingLoadingAnimator: FKLoadingBaseAnimator {
  /// Mask layer defining ring geometry.
  private let maskRing = CAShapeLayer()
  /// Gradient layer that provides multi-color output.
  private let gradientLayer = CAGradientLayer()

  /// Configures gradient ring layers.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the ring.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    gradientLayer.frame = bounds
    gradientLayer.startPoint = .init(x: 0, y: 0.5)
    gradientLayer.endPoint = .init(x: 1, y: 0.5)
    gradientLayer.colors = style.gradientColors.map(\.cgColor)
    maskRing.frame = bounds
    maskRing.fillColor = UIColor.clear.cgColor
    maskRing.strokeColor = UIColor.white.cgColor
    maskRing.lineWidth = style.ringWidth
    maskRing.lineCap = .round
    // Reuse static path geometry and animate rotation only for stable performance.
    maskRing.path = UIBezierPath(
      arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
      radius: min(bounds.width, bounds.height) * 0.36,
      startAngle: -.pi / 2,
      endAngle: .pi * 1.5,
      clockwise: true
    ).cgPath
    gradientLayer.mask = maskRing

    if gradientLayer.superlayer == nil {
      renderLayer.addSublayer(gradientLayer)
    }
  }

  /// Starts continuous rotation for the gradient ring.
  override func start() {
    stop()
    // Rotating the container is cheaper than animating gradient stops each frame.
    let spin = CABasicAnimation(keyPath: "transform.rotation.z")
    spin.fromValue = 0
    spin.toValue = Double.pi * 2
    spin.duration = style.duration / max(style.speed, 0.01)
    spin.repeatCount = style.repeatCount
    spin.timingFunction = CAMediaTimingFunction(name: .linear)
    renderLayer.add(spin, forKey: "gradient.spin")
  }
}

/// Determinate progress ring animator.
///
/// Uses a static track plus a foreground progress stroke that updates via `strokeEnd`.
final class FKProgressRingLoadingAnimator: FKLoadingBaseAnimator {
  /// Background ring track.
  private let trackLayer = CAShapeLayer()
  /// Foreground progress ring.
  private let progressLayer = CAShapeLayer()

  /// Configures track/progress layers.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the ring.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    // Shared path avoids duplicate geometry calculations and keeps both layers perfectly aligned.
    let path = UIBezierPath(
      arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
      radius: min(bounds.width, bounds.height) * 0.36,
      startAngle: -.pi / 2,
      endAngle: .pi * 1.5,
      clockwise: true
    ).cgPath

    trackLayer.frame = bounds
    trackLayer.fillColor = UIColor.clear.cgColor
    trackLayer.strokeColor = style.secondaryColor.withAlphaComponent(0.2).cgColor
    trackLayer.lineWidth = style.ringWidth
    trackLayer.path = path

    progressLayer.frame = bounds
    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.strokeColor = style.primaryColor.cgColor
    progressLayer.lineWidth = style.ringWidth
    progressLayer.lineCap = .round
    progressLayer.strokeEnd = 0
    progressLayer.path = path

    if trackLayer.superlayer == nil {
      renderLayer.addSublayer(trackLayer)
      renderLayer.addSublayer(progressLayer)
    }
  }

  /// Updates determinate ring progress.
  ///
  /// - Parameter progress: Normalized value in `0...1`.
  override func updateProgress(_ progress: CGFloat) {
    // Disable implicit animations to keep progress updates deterministic and list-friendly.
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    progressLayer.strokeEnd = min(max(progress, 0), 1)
    CATransaction.commit()
  }
}
