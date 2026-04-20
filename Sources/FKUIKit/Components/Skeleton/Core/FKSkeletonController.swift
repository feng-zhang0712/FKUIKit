//
// FKSkeletonController.swift
//

import UIKit

/// Controller responsible for managing generated skeleton overlays for one host view.
final class FKSkeletonController: FKSkeletonPresentable {
  private weak var hostView: UIView?
  private var overlays: [FKSkeletonView] = []
  private var originalInteractionEnabled: Bool?
  private let hiddenViewTable = NSMapTable<UIView, NSNumber>(keyOptions: .weakMemory, valueOptions: .strongMemory)

  init(hostView: UIView) {
    self.hostView = hostView
  }

  func showSkeleton(
    configuration: FKSkeletonConfiguration?,
    options: FKSkeletonDisplayOptions,
    animated: Bool
  ) {
    guard let hostView else { return }
    clear(animated: false, completion: nil)

    let config = configuration ?? FKSkeleton.defaultConfiguration
    let excluded = Set(options.excludedViews.map { ObjectIdentifier($0) })
    let targets = collectSkeletonTargets(in: hostView, excluded: excluded)

    guard !targets.isEmpty else { return }
    if originalInteractionEnabled == nil {
      originalInteractionEnabled = hostView.isUserInteractionEnabled
    }
    hostView.isUserInteractionEnabled = !options.blocksInteraction

    for target in targets {
      guard let superview = target.superview else { continue }
      let placeholder = FKSkeletonView()
      placeholder.configuration = mergedConfiguration(config: config, for: target)
      placeholder.translatesAutoresizingMaskIntoConstraints = false
      placeholder.isUserInteractionEnabled = false
      superview.addSubview(placeholder)
      superview.bringSubviewToFront(placeholder)
      NSLayoutConstraint.activate([
        placeholder.leadingAnchor.constraint(equalTo: target.leadingAnchor),
        placeholder.trailingAnchor.constraint(equalTo: target.trailingAnchor),
        placeholder.topAnchor.constraint(equalTo: target.topAnchor),
        placeholder.bottomAnchor.constraint(equalTo: target.bottomAnchor),
      ])
      applyShape(for: placeholder, target: target, config: config)
      placeholder.show(animated: animated)
      overlays.append(placeholder)

      if options.hidesTargetView {
        hiddenViewTable.setObject(NSNumber(value: Float(target.alpha)), forKey: target)
        target.alpha = 0
      }
    }
  }

  func hideSkeleton(animated: Bool, completion: (() -> Void)?) {
    clear(animated: animated, completion: completion)
  }

  private func clear(animated: Bool, completion: (() -> Void)?) {
    let group = DispatchGroup()
    for overlay in overlays {
      group.enter()
      overlay.hide(animated: animated) {
        overlay.removeFromSuperview()
        group.leave()
      }
    }
    overlays.removeAll(keepingCapacity: false)
    if let hostView, let originalInteractionEnabled {
      hostView.isUserInteractionEnabled = originalInteractionEnabled
    }
    originalInteractionEnabled = nil
    restoreHiddenViews()
    group.notify(queue: .main) { completion?() }
  }

  private func restoreHiddenViews() {
    let enumerator = hiddenViewTable.keyEnumerator()
    while let view = enumerator.nextObject() as? UIView {
      let original = hiddenViewTable.object(forKey: view)?.floatValue ?? 1
      view.alpha = CGFloat(original)
    }
    hiddenViewTable.removeAllObjects()
  }

  private func collectSkeletonTargets(in root: UIView, excluded: Set<ObjectIdentifier>) -> [UIView] {
    if excluded.contains(ObjectIdentifier(root)) { return [] }
    if root.fk_isSkeletonExcluded { return [] }
    if root is FKSkeletonView { return [] }

    let host = effectiveHost(for: root)
    return flattenTargets(from: host, excluded: excluded)
  }

  private func effectiveHost(for root: UIView) -> UIView {
    if let cell = root as? UITableViewCell { return cell.contentView }
    if let cell = root as? UICollectionViewCell { return cell.contentView }
    return root
  }

  private func flattenTargets(from view: UIView, excluded: Set<ObjectIdentifier>) -> [UIView] {
    if excluded.contains(ObjectIdentifier(view)) || view.fk_isSkeletonExcluded {
      return []
    }
    if shouldRenderSkeleton(for: view) {
      return [view]
    }
    var result: [UIView] = []
    if let stack = view as? UIStackView {
      for arranged in stack.arrangedSubviews {
        result.append(contentsOf: flattenTargets(from: arranged, excluded: excluded))
      }
    }
    for subview in view.subviews where !(view is UIStackView && (view as? UIStackView)?.arrangedSubviews.contains(subview) == true) {
      result.append(contentsOf: flattenTargets(from: subview, excluded: excluded))
    }
    return result
  }

  private func shouldRenderSkeleton(for view: UIView) -> Bool {
    guard !view.isHidden, view.alpha > 0.01 else { return false }
    if view is UILabel || view is UIImageView || view is UIButton || view is UITextField {
      return true
    }
    if view is UITableViewCell || view is UICollectionViewCell {
      return true
    }
    // For generic UIViews, only generate when it is a leaf so containers are not over-painted.
    return view.subviews.isEmpty && view.bounds.width > 1 && view.bounds.height > 1
  }

  private func mergedConfiguration(config: FKSkeletonConfiguration, for view: UIView) -> FKSkeletonConfiguration {
    if let override = view.fk_skeletonConfigurationOverride {
      return override
    }
    return config
  }

  private func applyShape(for skeleton: FKSkeletonView, target: UIView, config: FKSkeletonConfiguration) {
    let shape = target.fk_skeletonShape ?? .rounded
    switch shape {
    case .rectangle:
      skeleton.layer.cornerRadius = 0
    case .circle:
      let shortestSide = min(target.bounds.width, target.bounds.height)
      skeleton.layer.cornerRadius = shortestSide / 2
    case .rounded:
      skeleton.layer.cornerRadius = config.inheritsCornerRadius ? target.layer.cornerRadius : config.cornerRadius
    case .custom(let radius):
      skeleton.layer.cornerRadius = max(0, radius)
    }
    skeleton.layer.maskedCorners = target.layer.maskedCorners
  }
}
