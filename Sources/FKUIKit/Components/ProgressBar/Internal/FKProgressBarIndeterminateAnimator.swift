import QuartzCore
import UIKit

/// Owns repeating `CAAnimation` groups for marquee / breathing indeterminate modes.
final class FKProgressBarIndeterminateAnimator {
  private weak var marqueeLayer: CALayer?
  private weak var ringRotationLayer: CAShapeLayer?
  private var breathingTargets: [CALayer] = []
  private let marqueeKey = "fk_progress_marquee"
  private let breatheKey = "fk_progress_breathe"

  func attach(marquee: CALayer?, ringRotation: CAShapeLayer?) {
    marqueeLayer = marquee
    ringRotationLayer = ringRotation
  }

  func stopAll() {
    marqueeLayer?.removeAnimation(forKey: marqueeKey)
    ringRotationLayer?.removeAnimation(forKey: marqueeKey)
    for layer in breathingTargets {
      layer.removeAnimation(forKey: breatheKey)
    }
    breathingTargets = []
  }

  func startMarqueeLinear(
    period: TimeInterval,
    trackBounds: CGRect,
    axis: FKProgressBarAxis,
    capsuleFraction: CGFloat = 0.34,
    reducedMotion: Bool
  ) {
    guard let layer = marqueeLayer, !reducedMotion else { return }
    stopAll()
    switch axis {
    case .horizontal:
      let w = max(4, trackBounds.width * capsuleFraction)
      let h = trackBounds.height
      layer.bounds = CGRect(x: 0, y: 0, width: w, height: h)
      layer.position = CGPoint(x: trackBounds.minX - w / 2, y: trackBounds.midY)
      layer.cornerRadius = h / 2
      let anim = CABasicAnimation(keyPath: "position.x")
      anim.fromValue = trackBounds.minX - w / 2
      anim.toValue = trackBounds.maxX + w / 2
      anim.duration = period
      anim.repeatCount = .infinity
      anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      layer.add(anim, forKey: marqueeKey)
    case .vertical:
      let w = trackBounds.width
      let h = max(4, trackBounds.height * capsuleFraction)
      layer.bounds = CGRect(x: 0, y: 0, width: w, height: h)
      layer.position = CGPoint(x: trackBounds.midX, y: trackBounds.maxY + h / 2)
      layer.cornerRadius = w / 2
      let anim = CABasicAnimation(keyPath: "position.y")
      anim.fromValue = trackBounds.maxY + h / 2
      anim.toValue = trackBounds.minY - h / 2
      anim.duration = period
      anim.repeatCount = .infinity
      anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      layer.add(anim, forKey: marqueeKey)
    }
  }

  func startMarqueeRing(period: TimeInterval, reducedMotion: Bool) {
    guard let strokeLayer = ringRotationLayer, !reducedMotion else { return }
    stopAll()
    let anim = CABasicAnimation(keyPath: "transform.rotation.z")
    anim.byValue = CGFloat.pi * 2
    anim.duration = period
    anim.repeatCount = .infinity
    anim.isRemovedOnCompletion = false
    anim.isAdditive = true
    strokeLayer.add(anim, forKey: marqueeKey)
  }

  func startBreathing(layers: [CALayer], period: TimeInterval, reducedMotion: Bool) {
    guard !reducedMotion else { return }
    stopAll()
    breathingTargets = layers
    for layer in layers {
      let anim = CABasicAnimation(keyPath: "opacity")
      anim.fromValue = 1
      anim.toValue = 0.35
      anim.duration = period / 2
      anim.autoreverses = true
      anim.repeatCount = .infinity
      anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      layer.add(anim, forKey: breatheKey)
    }
  }
}
