//
// FKSkeletonContainerView.swift
//

import UIKit

/// A composable container that holds multiple `FKSkeletonView` blocks arranged via AutoLayout.
///
/// Build complex skeleton layouts (cards, list rows, content areas) by adding skeleton views
/// as subviews and constraining them normally. Call `showSkeleton()` / `hideSkeleton()` on
/// the container to control all children at once.
///
/// When `usesUnifiedShimmer` is `true` (default), a **single** animated gradient is masked to
/// all blocks so scrolling tables do not schedule one `CABasicAnimation` per line.
open class FKSkeletonContainerView: UIView {

  // MARK: - Public

  /// Per-instance configuration propagated to all managed skeleton subviews (and the unified shimmer).
  public var configuration: FKSkeletonConfiguration? {
    didSet {
      propagateConfiguration()
      unifiedShimmerHost?.apply(configuration: resolvedConfiguration)
    }
  }

  /// When `true`, one shared highlight animation covers all blocks; each block only draws base fill.
  public var usesUnifiedShimmer: Bool = true {
    didSet {
      guard usesUnifiedShimmer != oldValue else { return }
      applyUnifiedModeChange()
      setNeedsLayout()
    }
  }

  /// All skeleton subviews registered via `addSkeletonSubview(_:)`.
  public private(set) var skeletonSubviews: [FKSkeletonView] = []

  // MARK: - Private

  private var unifiedShimmerHost: FKSkeletonUnifiedShimmerHost?

  private var resolvedConfiguration: FKSkeletonConfiguration {
    configuration ?? FKSkeleton.defaultConfiguration
  }

  // MARK: - Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
  }

  // MARK: - Subview management

  /// Add a skeleton block as a managed subview (sets `translatesAutoresizingMaskIntoConstraints = false`).
  public func addSkeletonSubview(_ view: FKSkeletonView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    view.configuration = configuration
    syncSuppression(for: view)
    addSubview(view)
    skeletonSubviews.append(view)
    ensureUnifiedHostIfNeeded()
    setNeedsLayout()
  }

  /// Remove a previously added skeleton subview.
  public func removeSkeletonSubview(_ view: FKSkeletonView) {
    view.removeFromSuperview()
    skeletonSubviews.removeAll { $0 === view }
    if skeletonSubviews.isEmpty {
      unifiedShimmerHost?.removeFromSuperview()
      unifiedShimmerHost = nil
    }
    setNeedsLayout()
  }

  /// Removes every registered skeleton block (e.g. before reusing a host view with a new preset).
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

  // MARK: - Show / Hide

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

  public func hideSkeleton(animated: Bool = true) {
    unifiedShimmerHost?.stopAnimating()
    skeletonSubviews.forEach { $0.hide(animated: animated) }
    if !animated {
      unifiedShimmerHost?.isHidden = true
    }
  }

  // MARK: - Layout

  open override func layoutSubviews() {
    super.layoutSubviews()
    guard usesUnifiedShimmer, let host = unifiedShimmerHost else { return }
    host.updateMask(skeletonViews: skeletonSubviews, in: self)
  }

  // MARK: - Private

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
