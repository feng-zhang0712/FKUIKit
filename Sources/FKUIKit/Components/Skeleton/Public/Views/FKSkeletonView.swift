import UIKit

/// Single placeholder block; embed in a hierarchy or use standalone.
open class FKSkeletonView: UIView {

  /// Overrides ``FKSkeleton.defaultConfiguration`` when non-`nil`.
  public var configuration: FKSkeletonConfiguration? {
    didSet { reconfigure() }
  }

  /// When `true`, only the base fill runs locally while a parent ``FKSkeletonContainerView`` drives a shared shimmer mask.
  public var isShimmerSuppressed: Bool = false {
    didSet { reconfigure() }
  }

  private let skeletonLayer = FKSkeletonLayer()
  private var isShowingSkeleton = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    isAccessibilityElement = false
    accessibilityElementsHidden = true
    layer.addSublayer(skeletonLayer)
    reconfigure()
    show(animated: false)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skeletonLayer.frame = bounds
    let config = resolvedConfiguration
    if config.inheritsCornerRadius {
      skeletonLayer.cornerRadius = layer.cornerRadius
    } else {
      skeletonLayer.cornerRadius = config.cornerRadius
    }
    CATransaction.commit()
  }

  public func show(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard !isShowingSkeleton else {
      completion?()
      return
    }
    isShowingSkeleton = true
    isHidden = false
    let config = resolvedConfiguration
    if animated && config.transitionDuration > 0 {
      alpha = 0
      UIView.animate(withDuration: config.transitionDuration, animations: { self.alpha = 1 }, completion: { _ in
        completion?()
      })
    } else {
      alpha = 1
      completion?()
    }
    startBlockAnimationIfNeeded()
  }

  public func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard isShowingSkeleton else {
      completion?()
      return
    }
    isShowingSkeleton = false
    let config = resolvedConfiguration
    let finish = {
      self.isHidden = true
      self.skeletonLayer.stopAnimations()
      completion?()
    }
    if animated && config.transitionDuration > 0 {
      UIView.animate(withDuration: config.transitionDuration, animations: {
        self.alpha = 0
      }, completion: { _ in finish() })
    } else {
      alpha = 0
      finish()
    }
  }

  func startBlockAnimationIfNeeded() {
    let config = resolvedConfiguration
    guard isShowingSkeleton else { return }
    if isShimmerSuppressed { return }
    guard config.animationMode != .none else {
      skeletonLayer.stopAnimations()
      return
    }
    skeletonLayer.startAnimations(config: config)
  }

  private var resolvedConfiguration: FKSkeletonConfiguration {
    configuration ?? FKSkeleton.defaultConfiguration
  }

  private func reconfigure() {
    let config = resolvedConfiguration
    skeletonLayer.apply(config, shimmerSuppressed: isShimmerSuppressed)
    if isShowingSkeleton {
      startBlockAnimationIfNeeded()
    }
    setNeedsLayout()
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
    refreshSkeletonAppearanceForCurrentTraits()
  }

  /// Re-resolves dynamic colors into Core Animation layers (also invoked on trait changes).
  public func refreshSkeletonAppearanceForCurrentTraits() {
    reconfigure()
  }
}
