import UIKit

/// Hosts multiple ``FKSkeletonView`` placeholders and optionally shares one shimmer animation across them.
open class FKSkeletonContainerView: UIView {

  /// Shared configuration pushed to every registered block (and the unified shimmer layer).
  public var configuration: FKSkeletonConfiguration? {
    didSet {
      propagateConfiguration()
      unifiedShimmerHost?.apply(configuration: resolvedConfiguration)
    }
  }

  /// When `true`, one gradient animates behind a mask of all blocks (recommended for scrolling lists).
  public var usesUnifiedShimmer: Bool = true {
    didSet {
      guard usesUnifiedShimmer != oldValue else { return }
      applyUnifiedModeChange()
      setNeedsLayout()
    }
  }

  /// Skeleton blocks added through ``addSkeletonSubview(_:)``.
  public private(set) var skeletonSubviews: [FKSkeletonView] = []

  private var unifiedShimmerHost: FKSkeletonUnifiedShimmerHost?

  private var resolvedConfiguration: FKSkeletonConfiguration {
    configuration ?? FKSkeleton.defaultConfiguration
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
  }

  public func addSkeletonSubview(_ view: FKSkeletonView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    view.configuration = configuration
    syncSuppression(for: view)
    addSubview(view)
    skeletonSubviews.append(view)
    ensureUnifiedHostIfNeeded()
    setNeedsLayout()
  }

  public func removeSkeletonSubview(_ view: FKSkeletonView) {
    view.removeFromSuperview()
    skeletonSubviews.removeAll { $0 === view }
    if skeletonSubviews.isEmpty {
      unifiedShimmerHost?.removeFromSuperview()
      unifiedShimmerHost = nil
    }
    setNeedsLayout()
  }

  public func removeAllSkeletonSubviews() {
    let copy = Array(skeletonSubviews)
    for view in copy {
      view.removeFromSuperview()
    }
    skeletonSubviews.removeAll(keepingCapacity: false)
    unifiedShimmerHost?.stopAnimating()
    unifiedShimmerHost?.removeFromSuperview()
    unifiedShimmerHost = nil
    setNeedsLayout()
  }

  public func showSkeleton(animated: Bool = true) {
    skeletonSubviews.forEach { $0.show(animated: animated) }
    unifiedShimmerHost?.isHidden = false
    unifiedShimmerHost?.alpha = 1
    if usesUnifiedShimmer {
      let config = resolvedConfiguration
      unifiedShimmerHost?.apply(configuration: config)
      unifiedShimmerHost?.startAnimating(configuration: config)
    }
  }

  /// Hides child blocks and fades the unified shimmer layer when enabled.
  public func hideSkeleton(animated: Bool = true, completion: (() -> Void)? = nil) {
    let config = resolvedConfiguration
    unifiedShimmerHost?.stopAnimating()

    let group = DispatchGroup()

    if usesUnifiedShimmer, let host = unifiedShimmerHost {
      group.enter()
      let finishHost = {
        host.isHidden = true
        host.alpha = 1
        group.leave()
      }
      if animated && config.transitionDuration > 0 {
        UIView.animate(withDuration: config.transitionDuration, animations: {
          host.alpha = 0
        }, completion: { _ in finishHost() })
      } else {
        host.alpha = 0
        finishHost()
      }
    }

    if skeletonSubviews.isEmpty {
      group.notify(queue: .main) {
        completion?()
      }
      return
    }

    for subview in skeletonSubviews {
      group.enter()
      subview.hide(animated: animated) {
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion?()
    }
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    guard usesUnifiedShimmer, let host = unifiedShimmerHost else { return }
    host.updateMask(skeletonViews: skeletonSubviews, in: self)
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
    unifiedShimmerHost?.apply(configuration: resolvedConfiguration)
  }

  private func propagateConfiguration() {
    skeletonSubviews.forEach { $0.configuration = configuration }
    unifiedShimmerHost?.apply(configuration: resolvedConfiguration)
  }

  private func ensureUnifiedHostIfNeeded() {
    guard usesUnifiedShimmer else { return }
    if unifiedShimmerHost == nil {
      let host = FKSkeletonUnifiedShimmerHost()
      host.translatesAutoresizingMaskIntoConstraints = false
      host.apply(configuration: resolvedConfiguration)
      addSubview(host)
      NSLayoutConstraint.activate([
        host.topAnchor.constraint(equalTo: topAnchor),
        host.leadingAnchor.constraint(equalTo: leadingAnchor),
        host.trailingAnchor.constraint(equalTo: trailingAnchor),
        host.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
      unifiedShimmerHost = host
    }
    unifiedShimmerHost.map { bringSubviewToFront($0) }
  }

  private func applyUnifiedModeChange() {
    skeletonSubviews.forEach { syncSuppression(for: $0) }
    if usesUnifiedShimmer {
      ensureUnifiedHostIfNeeded()
      unifiedShimmerHost?.apply(configuration: resolvedConfiguration)
      unifiedShimmerHost?.startAnimating(configuration: resolvedConfiguration)
    } else {
      unifiedShimmerHost?.stopAnimating()
      unifiedShimmerHost?.removeFromSuperview()
      unifiedShimmerHost = nil
      skeletonSubviews.forEach { $0.startBlockAnimationIfNeeded() }
    }
  }

  private func syncSuppression(for view: FKSkeletonView) {
    view.isShimmerSuppressed = usesUnifiedShimmer
  }
}
