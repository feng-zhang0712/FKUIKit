//
// FKSkeletonLayer.swift
//

import UIKit

/// Renders one skeleton block: base fill plus an optional animated highlight gradient.
final class FKSkeletonLayer: CALayer {

  // MARK: - Sublayers

  private let gradientLayer = CAGradientLayer()

  // MARK: - Init

  override init() {
    super.init()
    setupGradient()
  }

  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupGradient()
  }

  // MARK: - Setup

  private func setupGradient() {
    gradientLayer.locations = [0, 0.5, 1]
    addSublayer(gradientLayer)
  }

  // MARK: - Layout

  override func layoutSublayers() {
    super.layoutSublayers()
    gradientLayer.frame = bounds
  }

  // MARK: - Configuration

  /// - Parameter shimmerSuppressed: When `true`, only the base color is drawn (used when a parent drives a single shared shimmer).
  func apply(_ config: FKSkeletonConfiguration, shimmerSuppressed: Bool) {
    masksToBounds = true
    cornerCurve = .continuous
    backgroundColor = config.baseColor.cgColor
    borderColor = config.baseColor.withAlphaComponent(0.85).cgColor
    borderWidth = config.borderWidth

    if shimmerSuppressed {
      gradientLayer.isHidden = true
      stopAnimations()
      return
    }

    gradientLayer.isHidden = config.animationMode == .none
    let gradientPalette = config.gradientColors?.isEmpty == false
      ? (config.gradientColors ?? [config.baseColor, config.highlightColor, config.baseColor])
      : [config.baseColor, config.highlightColor, config.baseColor]
    let colors = gradientPalette.map { $0.cgColor }
    gradientLayer.colors = colors
    gradientLayer.opacity = 1
    applyDirection(config.shimmerDirection)
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

  // MARK: - Animation

  func startAnimations(config: FKSkeletonConfiguration) {
    stopAnimations()
    switch config.animationMode {
    case .shimmer:
      startShimmer(duration: config.animationDuration)
    case .pulse, .breathing:
      startBreathing(config: config)
    case .none:
      break
    }
  }

  func stopAnimations() {
    gradientLayer.removeAllAnimations()
  }

  private func startShimmer(duration: TimeInterval) {
    let animation = FKSkeletonAnimationFactory.shimmer(duration: duration)
    gradientLayer.add(animation, forKey: "shimmer")
  }

  private func startBreathing(config: FKSkeletonConfiguration) {
    let animation = FKSkeletonAnimationFactory.pulse(
      duration: config.animationDuration,
      minOpacity: Float(config.breathingMinOpacity)
    )
    gradientLayer.add(animation, forKey: "pulse")
  }
}
