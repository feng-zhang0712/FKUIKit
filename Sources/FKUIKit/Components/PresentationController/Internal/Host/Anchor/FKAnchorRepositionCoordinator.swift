import UIKit

@MainActor
final class FKAnchorRepositionCoordinator {
  private weak var probeView: FKAnchorRepositionProbeView?
  private var isScheduled = false
  private var onReposition: (() -> Void)?
  private var debounceInterval: TimeInterval = 0
  private var pendingWorkItem: DispatchWorkItem?

  func startObserving(
    in host: UIView,
    listenLayoutChanges: Bool,
    listenTraitChanges: Bool,
    debounceInterval: TimeInterval,
    onRepositionRequested: @escaping () -> Void
  ) {
    self.onReposition = onRepositionRequested
    self.debounceInterval = max(0, debounceInterval)

    let probe: FKAnchorRepositionProbeView
    if let existing = probeView, existing.superview === host {
      probe = existing
    } else {
      probeView?.removeFromSuperview()
      let newProbe = FKAnchorRepositionProbeView(frame: host.bounds)
      newProbe.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      newProbe.isUserInteractionEnabled = false
      host.addSubview(newProbe)
      host.sendSubviewToBack(newProbe)
      probeView = newProbe
      probe = newProbe
    }

    probe.onHostChange = { [weak self] didLayoutChange, didTraitChange in
      guard let self else { return }
      if didLayoutChange, !listenLayoutChanges { return }
      if didTraitChange, !listenTraitChanges { return }
      self.schedule()
    }
  }

  func stopObserving() {
    pendingWorkItem?.cancel()
    pendingWorkItem = nil
    probeView?.removeFromSuperview()
    probeView = nil
    isScheduled = false
    onReposition = nil
  }

  private func schedule() {
    if debounceInterval > 0 {
      pendingWorkItem?.cancel()
      let item = DispatchWorkItem { [weak self] in
        Task { @MainActor [weak self] in
          self?.onReposition?()
        }
      }
      pendingWorkItem = item
      DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: item)
      return
    }

    guard !isScheduled else { return }
    isScheduled = true
    DispatchQueue.main.async { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.isScheduled = false
        self.onReposition?()
      }
    }
  }
}

private final class FKAnchorRepositionProbeView: UIView {
  var onHostChange: ((_ didLayoutChange: Bool, _ didTraitChange: Bool) -> Void)?
  private var lastBoundsSize: CGSize = .zero

  override init(frame: CGRect) {
    super.init(frame: frame)
    isHidden = true
    lastBoundsSize = bounds.size
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    let didLayoutChange = bounds.size != lastBoundsSize
    lastBoundsSize = bounds.size
    guard didLayoutChange else { return }
    onHostChange?(true, false)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard let previousTraitCollection else { return }
    let didTraitChange =
      previousTraitCollection.horizontalSizeClass != traitCollection.horizontalSizeClass ||
      previousTraitCollection.verticalSizeClass != traitCollection.verticalSizeClass ||
      previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle ||
      previousTraitCollection.displayScale != traitCollection.displayScale
    guard didTraitChange else { return }
    onHostChange?(false, true)
  }
}
