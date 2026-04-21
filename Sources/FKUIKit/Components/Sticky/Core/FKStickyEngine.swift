//
// FKStickyEngine.swift
//

import UIKit

/// High-performance sticky coordinator for a single scroll view.
@MainActor
public final class FKStickyEngine: NSObject, FKStickyControllable {
  private weak var scrollView: UIScrollView?
  private var configuration: FKStickyConfiguration
  private var targets: [FKStickyTarget] = []
  private var stickyIDs = Set<String>()
  private var isUpdating = false

  /// Creates an engine and binds it to a scroll view.
  public init(scrollView: UIScrollView, configuration: FKStickyConfiguration = .default) {
    self.scrollView = scrollView
    self.configuration = configuration
    super.init()
  }

  /// Feeds current scroll event into sticky calculation.
  public func handleScroll() {
    reloadLayout()
  }

  public func apply(configuration: FKStickyConfiguration) {
    self.configuration = configuration
    reloadLayout()
  }

  public func setTargets(_ targets: [FKStickyTarget]) {
    self.targets = targets
    reloadLayout()
  }

  public func addTarget(_ target: FKStickyTarget) {
    targets.removeAll { $0.id == target.id }
    targets.append(target)
    reloadLayout()
  }

  public func removeTarget(withID id: String) {
    guard !id.isEmpty else { return }
    targets.removeAll { $0.id == id }
    stickyIDs.remove(id)
    reloadLayout()
  }

  public func setTargetEnabled(_ isEnabled: Bool, forID id: String) {
    guard let index = targets.firstIndex(where: { $0.id == id }) else { return }
    targets[index].isEnabled = isEnabled
    reloadLayout()
  }

  public func setEnabled(_ isEnabled: Bool) {
    configuration.isEnabled = isEnabled
    reloadLayout()
  }

  public func reloadLayout() {
    guard let scrollView else { return }
    guard !isUpdating else { return }
    isUpdating = true
    defer { isUpdating = false }

    let effectiveTopInset = makeBaseTopInset(for: scrollView)
    let effectiveOffsetY = scrollView.contentOffset.y + effectiveTopInset
    configuration.onDidScroll?(scrollView, effectiveOffsetY)

    guard configuration.isEnabled else {
      resetStickyState()
      return
    }

    // Multi-target chaining:
    // each sticky view reserves its own height to avoid overlap glitches.
    var consumedTop: CGFloat = 0
    let sortedTargets = targets.sorted { lhs, rhs in
      lhs.threshold < rhs.threshold
    }

    for target in sortedTargets {
      guard target.isEnabled, let view = target.viewProvider() else {
        continue
      }

      let topInset = target.fixedTopInset ?? effectiveTopInset
      let threshold = target.threshold + target.activationOffset
      let triggerY = topInset + consumedTop
      let shouldSticky = effectiveOffsetY >= threshold
      let translationY = shouldSticky ? max(0, effectiveOffsetY - threshold + triggerY - topInset) : 0

      apply(transformY: translationY, to: view)
      updateStateIfNeeded(for: target, shouldSticky: shouldSticky, view: view)

      if shouldSticky {
        consumedTop += view.bounds.height
      }
    }
  }

  public func resetStickyState() {
    for target in targets {
      guard let view = target.viewProvider() else { continue }
      apply(transformY: 0, to: view)
      if stickyIDs.contains(target.id) {
        target.onStyleChanged?(.normal, view)
        target.onStateChanged?(.didUnsticky(id: target.id))
      }
    }
    stickyIDs.removeAll()
  }

  private func updateStateIfNeeded(for target: FKStickyTarget, shouldSticky: Bool, view: UIView) {
    let isSticky = stickyIDs.contains(target.id)
    switch (isSticky, shouldSticky) {
    case (false, true):
      target.onStateChanged?(.willSticky(id: target.id))
      target.onStyleChanged?(.sticky, view)
      target.onStateChanged?(.didSticky(id: target.id))
      stickyIDs.insert(target.id)
    case (true, false):
      target.onStyleChanged?(.normal, view)
      target.onStateChanged?(.didUnsticky(id: target.id))
      stickyIDs.remove(target.id)
    default:
      break
    }
  }

  private func makeBaseTopInset(for scrollView: UIScrollView) -> CGFloat {
    let adjustedInset = configuration.usesAdjustedContentInset ? scrollView.adjustedContentInset.top : 0
    let safeAreaInset = configuration.adaptsSafeArea ? scrollView.safeAreaInsets.top : 0
    return max(adjustedInset, safeAreaInset) + configuration.additionalTopInset
  }

  private func apply(transformY: CGFloat, to view: UIView) {
    guard abs(view.transform.ty - transformY) > 0.5 else { return }
    view.transform = CGAffineTransform(translationX: 0, y: transformY)
    if view.layer.shadowOpacity > 0 {
      // Keep shadow path updated to avoid offscreen rendering and preserve frame rate.
      view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
    }
  }
}
