import UIKit

/// High-performance sticky coordinator for a single scroll view.
public final class FKStickyEngine: NSObject, FKStickyControllable {
  private weak var scrollView: UIScrollView?
  private var configuration: FKStickyConfiguration
  private var targets: [FKStickyTarget] = []
  private var stickyIDs = Set<String>()
  private var forcedStickyID: String?
  private var isUpdating = false

  /// Creates an engine and binds it to a scroll view.
  public init(scrollView: UIScrollView, configuration: FKStickyConfiguration = .default) {
    self.scrollView = scrollView
    self.configuration = configuration
    super.init()
  }

  /// Feeds current scroll event into sticky calculation.
  public func handleScroll() {
    reloadLayoutInternal()
  }

  public func apply(configuration: FKStickyConfiguration) {
    self.configuration = configuration
    reloadLayoutInternal()
  }

  public func setTargets(_ targets: [FKStickyTarget]) {
    self.targets = targets
    reloadLayoutInternal()
  }

  public func addTarget(_ target: FKStickyTarget) {
    targets.removeAll { $0.id == target.id }
    targets.append(target)
    reloadLayoutInternal()
  }

  public func removeTarget(withID id: String) {
    guard !id.isEmpty else { return }
    targets.removeAll { $0.id == id }
    stickyIDs.remove(id)
    if forcedStickyID == id {
      forcedStickyID = nil
    }
    reloadLayoutInternal()
  }

  public func setTargetEnabled(_ isEnabled: Bool, forID id: String) {
    guard let index = targets.firstIndex(where: { $0.id == id }) else { return }
    targets[index].isEnabled = isEnabled
    reloadLayoutInternal()
  }

  public func setActiveStickyTarget(withID id: String?) {
    forcedStickyID = id
    reloadLayoutInternal()
  }

  public func setEnabled(_ isEnabled: Bool) {
    configuration.isEnabled = isEnabled
    reloadLayoutInternal()
  }

  public func reloadLayout() {
    reloadLayoutInternal()
  }

  public func resetStickyState() {
    resetStickyStateInternal()
  }

  private func reloadLayoutInternal() {
    guard let scrollView else { return }
    guard !isUpdating else { return }
    isUpdating = true
    defer { isUpdating = false }

    let effectiveTopInset = makeBaseTopInset(for: scrollView)
    let effectiveOffsetY = scrollView.contentOffset.y + effectiveTopInset
    configuration.onDidScroll?(scrollView, effectiveOffsetY)

    guard configuration.isEnabled else {
      resetStickyStateInternal()
      return
    }

    let sortedTargets = targets
      .filter(\.isEnabled)
      .sorted { $0.threshold < $1.threshold }
    var activeIDs = Set<String>()

    for (index, target) in sortedTargets.enumerated() {
      guard let view = target.viewProvider() else {
        continue
      }

      let topInset = (target.fixedTopInset ?? effectiveTopInset) + configuration.referenceOffsetY
      let threshold = target.threshold + target.activationOffset
      let nextThreshold: CGFloat? = {
        guard index + 1 < sortedTargets.count else { return nil }
        return sortedTargets[index + 1].threshold + sortedTargets[index + 1].activationOffset
      }()

      let baselineY = scrollView.contentOffset.y + topInset
      let clampedY = min(nextThreshold.map { $0 - view.bounds.height } ?? baselineY, baselineY)
      let targetPinnedY = max(threshold, clampedY)
      var shouldSticky = baselineY >= threshold
      if let forcedStickyID {
        shouldSticky = forcedStickyID == target.id
      }

      let progress = makeTransitionProgress(
        baselineY: baselineY,
        threshold: threshold,
        distance: configuration.transitionDistance,
        curve: configuration.animationCurve
      )
      target.onTransition?(progress, view)

      let translationY = shouldSticky ? max(0, targetPinnedY - threshold) : 0

      apply(transformY: translationY, to: view)
      updateStateIfNeeded(for: target, shouldSticky: shouldSticky, view: view)
      if shouldSticky { activeIDs.insert(target.id) }
    }

    cleanupInactiveStickyState(activeIDs: activeIDs)
  }

  private func resetStickyStateInternal() {
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

  private func cleanupInactiveStickyState(activeIDs: Set<String>) {
    let removedIDs = stickyIDs.subtracting(activeIDs)
    guard !removedIDs.isEmpty else { return }
    stickyIDs = activeIDs
    for target in targets where removedIDs.contains(target.id) {
      guard let view = target.viewProvider() else { continue }
      target.onStyleChanged?(.normal, view)
      target.onStateChanged?(.didUnsticky(id: target.id))
    }
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

  private func makeTransitionProgress(
    baselineY: CGFloat,
    threshold: CGFloat,
    distance: CGFloat,
    curve: FKStickyConfiguration.AnimationCurve
  ) -> CGFloat {
    let raw = (baselineY - threshold) / max(distance, 1)
    return curve.value(for: raw)
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
