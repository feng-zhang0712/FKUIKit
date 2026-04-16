//
// FKPresentationRepositionCoordinator.swift
//

import UIKit

@MainActor
final class FKPresentationRepositionCoordinator {
  private weak var probeView: FKPresentationRepositionProbeView?
  private var isRepositionScheduled: Bool = false
  private var onRepositionRequested: (() -> Void)?

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

  func stopObserving() {
    probeView?.removeFromSuperview()
    probeView = nil
    isRepositionScheduled = false
    onRepositionRequested = nil
  }

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
