//
// FKLoadingClassicAnimators.swift
//

import QuartzCore
import UIKit

/// Enhanced system spinner animator.
///
/// Wraps `UIActivityIndicatorView` while integrating with the shared animator protocol.
@MainActor
final class FKSpinnerLoadingAnimator: FKLoadingBaseAnimator {
  /// System activity indicator used as the rendering source.
  private lazy var spinner = UIActivityIndicatorView(style: .medium)

  /// Initializes the spinner animator and attaches indicator layer once.
  override init() {
    super.init()
    spinner.hidesWhenStopped = false
    renderLayer.addSublayer(spinner.layer)
  }

  /// Configures spinner color and layout.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the spinner.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    spinner.color = style.primaryColor
    spinner.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
  }

  /// Starts system spinner animation.
  override func start() {
    spinner.startAnimating()
  }

  /// Stops system spinner animation and clears inherited CA animations.
  override func stop() {
    spinner.stopAnimating()
    super.stop()
  }
}

/// Pulse animator supporting circular and square variants.
final class FKPulseLoadingAnimator: FKLoadingBaseAnimator {
  /// Shape layer used for pulse rendering.
  private let pulseLayer = CAShapeLayer()
  /// Controls whether the pulse shape is square (`true`) or circular (`false`).
  private let isSquare: Bool

  /// Creates a pulse animator variant.
  ///
  /// - Parameter isSquare: `true` for square pulse, `false` for circular pulse.
  init(isSquare: Bool) {
    self.isSquare = isSquare
    super.init()
  }

  /// Configures pulse shape and fill color.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the pulse.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    let side = min(bounds.width, bounds.height) * 0.5
    let rect = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
    pulseLayer.path = isSquare ? UIBezierPath(roundedRect: rect, cornerRadius: style.cornerRadius * 0.4).cgPath : UIBezierPath(ovalIn: rect).cgPath
    pulseLayer.fillColor = style.primaryColor.cgColor
    if pulseLayer.superlayer == nil {
      renderLayer.addSublayer(pulseLayer)
    }
  }

  /// Starts breathing pulse animation.
  override func start() {
    stop()

    // Scale animation creates breathing expansion and contraction.
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 0.7
    scale.toValue = 1.05
    scale.duration = style.duration / max(style.speed, 0.01)
    scale.autoreverses = true
    scale.repeatCount = style.repeatCount

    // Opacity animation reinforces breathing depth.
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 1
    opacity.toValue = 0.35
    opacity.duration = scale.duration
    opacity.autoreverses = true
    opacity.repeatCount = style.repeatCount

    pulseLayer.add(scale, forKey: "pulse.scale")
    pulseLayer.add(opacity, forKey: "pulse.opacity")
  }
}

/// Rotating-dots animator.
///
/// Uses `CAReplicatorLayer` so one animated source dot produces the full spinner pattern.
final class FKRotatingDotsLoadingAnimator: FKLoadingBaseAnimator {
  /// Replicator layer for radial dot distribution.
  private let replicator = CAReplicatorLayer()
  /// Source dot layer.
  private let dot = CALayer()

  /// Configures radial dot geometry.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the dots.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    let count = 8
    let radius = min(bounds.width, bounds.height) * 0.05
    let orbit = min(bounds.width, bounds.height) * 0.34

    replicator.frame = bounds
    replicator.instanceCount = count
    replicator.instanceTransform = CATransform3DMakeRotation((2 * .pi) / CGFloat(count), 0, 0, 1)
    replicator.instanceDelay = style.duration / Double(count)

    dot.frame = CGRect(x: bounds.midX - radius, y: bounds.midY - orbit - radius, width: radius * 2, height: radius * 2)
    dot.cornerRadius = radius
    dot.backgroundColor = style.primaryColor.cgColor

    if dot.superlayer == nil {
      replicator.addSublayer(dot)
    }
    if replicator.superlayer == nil {
      renderLayer.addSublayer(replicator)
    }
  }

  /// Starts dot opacity animation.
  override func start() {
    stop()
    // Instance delay converts one opacity timeline into a rotating illusion.
    let anim = CABasicAnimation(keyPath: "opacity")
    anim.fromValue = 1
    anim.toValue = 0.15
    anim.duration = style.duration / max(style.speed, 0.01)
    anim.repeatCount = style.repeatCount
    dot.add(anim, forKey: "dots.opacity")
  }
}

/// Gear-shaped stroke animator.
///
/// Draws a procedural gear path and rotates it continuously.
final class FKGearLoadingAnimator: FKLoadingBaseAnimator {
  /// Shape layer used to render the gear outline.
  private let gearLayer = CAShapeLayer()

  /// Configures gear path and stroke style.
  ///
  /// - Parameters:
  ///   - style: Shared style options.
  ///   - bounds: Drawing bounds for the gear.
  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    // Build vector path once per layout/update; transform animation handles runtime motion.
    gearLayer.path = gearPath(in: bounds).cgPath
    gearLayer.fillColor = UIColor.clear.cgColor
    gearLayer.strokeColor = style.primaryColor.cgColor
    gearLayer.lineWidth = style.lineWidth
    if gearLayer.superlayer == nil {
      renderLayer.addSublayer(gearLayer)
    }
  }

  /// Starts continuous gear rotation.
  override func start() {
    stop()
    let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
    rotation.fromValue = 0
    rotation.toValue = Double.pi * 2
    rotation.duration = style.duration / max(style.speed, 0.01)
    rotation.repeatCount = style.repeatCount
    rotation.timingFunction = CAMediaTimingFunction(name: .linear)
    gearLayer.add(rotation, forKey: "gear.rotate")
  }

  /// Generates a gear-like bezier path from alternating outer/inner vertices.
  ///
  /// - Parameter rect: Target drawing bounds.
  /// - Returns: Closed path containing teeth and a center cutout.
  private func gearPath(in rect: CGRect) -> UIBezierPath {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) * 0.32
    let inner = outer * 0.65
    let teeth = 8
    let path = UIBezierPath()

    // Alternate between outer and inner radii to form teeth.
    for i in 0..<(teeth * 2) {
      let angle = CGFloat(i) * (.pi / CGFloat(teeth))
      let radius = i.isMultiple(of: 2) ? outer : inner
      let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
      if i == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    path.close()
    path.append(UIBezierPath(ovalIn: CGRect(x: center.x - inner * 0.45, y: center.y - inner * 0.45, width: inner * 0.9, height: inner * 0.9)))
    return path
  }
}
