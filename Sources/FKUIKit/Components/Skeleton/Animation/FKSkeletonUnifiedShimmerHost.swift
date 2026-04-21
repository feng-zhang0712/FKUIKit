//
// FKSkeletonUnifiedShimmerHost.swift
//

import UIKit

/// One shared highlight gradient for an entire `FKSkeletonContainerView`, masked to all child blocks.
final class FKSkeletonUnifiedShimmerHost: UIView {

  private let gradientLayer = CAGradientLayer()
  private let shapeMask = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    accessibilityElementsHidden = true
    backgroundColor = .clear
    layer.addSublayer(gradientLayer)
    gradientLayer.mask = shapeMask
    shapeMask.fillColor = UIColor.white.cgColor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
    shapeMask.frame = gradientLayer.bounds
  }

  func apply(configuration config: FKSkeletonConfiguration) {
    let gradientPalette = config.gradientColors?.isEmpty == false
      ? (config.gradientColors ?? [config.baseColor, config.highlightColor, config.baseColor])
      : [config.baseColor, config.highlightColor, config.baseColor]
    let colors = gradientPalette.map { $0.cgColor }
    gradientLayer.colors = colors
    gradientLayer.locations = [0, 0.5, 1]
    applyDirection(config.shimmerDirection)
  }

  func updateMask(skeletonViews: [FKSkeletonView], in container: UIView) {
    let path = CGMutablePath()
    for v in skeletonViews where !v.isHidden && v.alpha > 0.01 {
      let rect = v.convert(v.bounds, to: container)
      guard rect.width > 0.01, rect.height > 0.01 else { continue }
      let rawRadius: CGFloat
      let config = v.configuration ?? FKSkeleton.defaultConfiguration
      if config.inheritsCornerRadius {
        rawRadius = v.layer.cornerRadius
      } else {
        rawRadius = config.cornerRadius
      }
      let r = min(rawRadius, min(rect.width, rect.height) / 2)
      path.addRoundedRect(in: rect, cornerWidth: r, cornerHeight: r)
    }
    shapeMask.path = path
  }

  func startAnimating(configuration config: FKSkeletonConfiguration) {
    gradientLayer.removeAllAnimations()
    switch config.animationMode {
    case .shimmer:
      let animation = FKSkeletonAnimationFactory.shimmer(duration: config.animationDuration)
      gradientLayer.add(animation, forKey: "shimmer")
    case .pulse, .breathing:
      let animation = FKSkeletonAnimationFactory.pulse(
        duration: config.animationDuration,
        minOpacity: Float(config.breathingMinOpacity)
      )
      gradientLayer.add(animation, forKey: "pulse")
    case .none:
      break
    }
  }

  func stopAnimating() {
    gradientLayer.removeAllAnimations()
  }

  private func applyDirection(_ direction: FKSkeletonShimmerDirection) {
    switch direction {
    case .leftToRight:
      gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
      gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
    case .rightToLeft:
      gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
      gradientLayer.endPoint   = CGPoint(x: 0, y: 0.5)
    case .topToBottom:
      gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
      gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
    case .bottomToTop:
      gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
      gradientLayer.endPoint   = CGPoint(x: 0.5, y: 0)
    case .diagonal:
      gradientLayer.startPoint = CGPoint(x: 0, y: 0)
      gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
    }
  }
}
