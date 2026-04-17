//
// FKPresentationRepositionCoordinator.swift
//

import UIKit

@MainActor
/// Coordinates automatic reposition requests for `FKPresentation`.
///
/// It installs a hidden `FKPresentationRepositionProbeView` in the host view,
/// listens for layout/trait changes, and triggers a debounced reposition callback.
final class FKPresentationRepositionCoordinator {
  /// Probe currently attached to host. Weak to avoid ownership cycles.
  private weak var probeView: FKPresentationRepositionProbeView?
  /// Coalescing flag to prevent multiple reposition callbacks in one runloop turn.
  private var isRepositionScheduled: Bool = false
  /// Callback executed when a reposition should occur.
  private var onRepositionRequested: (() -> Void)?

  /// Starts (or refreshes) host observation.
  ///
  /// - Parameters:
  ///   - host: Container view that presentation is anchored against.
  ///   - listenLayoutChanges: Whether host size/layout updates should trigger reposition.
  ///   - listenTraitChanges: Whether host trait updates should trigger reposition.
  ///   - onRepositionRequested: Called on main thread after coalescing.
  func startObserving(
    in host: UIView,
    listenLayoutChanges: Bool,
    listenTraitChanges: Bool,
    onRepositionRequested: @escaping () -> Void
  ) {
    self.onRepositionRequested = onRepositionRequested

    let probe: FKPresentationRepositionProbeView
    if let existing = probeView, existing.superview === host {
      probe = existing
    } else {
      probeView?.removeFromSuperview()
      let newProbe = FKPresentationRepositionProbeView(frame: host.bounds)
      newProbe.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      newProbe.backgroundColor = .clear
      newProbe.isUserInteractionEnabled = false
      host.addSubview(newProbe)
      host.sendSubviewToBack(newProbe)
      probeView = newProbe
      probe = newProbe
    }

    probe.onHostLayoutOrTraitChange = { [weak self] didLayoutChange, didTraitChange in
      guard let self else { return }
      if didLayoutChange, !listenLayoutChanges { return }
      if didTraitChange, !listenTraitChanges { return }
      self.scheduleReposition()
    }
  }

  /// Stops observation and clears pending callback state.
  func stopObserving() {
    probeView?.removeFromSuperview()
    probeView = nil
    isRepositionScheduled = false
    onRepositionRequested = nil
  }

  /// Schedules a single reposition callback in next main-queue turn.
  ///
  /// This avoids repeated reposition calculations when multiple host updates
  /// happen back-to-back within the same runloop cycle.
  private func scheduleReposition() {
    guard !isRepositionScheduled else { return }
    isRepositionScheduled = true
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.isRepositionScheduled = false
      self.onRepositionRequested?()
    }
  }
}
