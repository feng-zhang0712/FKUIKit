//
// FKSkeletonView.swift
//

import UIKit

/// A composable skeleton block. Use standalone or nest inside `FKSkeletonContainerView`.
///
/// Supports any shape: rectangle, circle (set `cornerRadius = half of width`), or custom radius.
open class FKSkeletonView: UIView {

  // MARK: - Public

  /// Per-instance configuration override. Falls back to `FKSkeleton.defaultConfiguration` when `nil`.
  public var configuration: FKSkeletonConfiguration? {
    didSet { reconfigure() }
  }

  /// When `true`, this block only paints the base fill; highlight motion is driven by a parent
  /// `FKSkeletonContainerView` with `usesUnifiedShimmer` so lists stay performant.
  public var isShimmerSuppressed: Bool = false {
    didSet { reconfigure() }
  }

  // MARK: - Private

  private let skeletonLayer = FKSkeletonLayer()
  private var isShowingSkeleton = false

  // MARK: - Init

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

  // MARK: - Layout

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

  // MARK: - Show / Hide

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

  // MARK: - Internal

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

  // MARK: - Private

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
}
