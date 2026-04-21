//
// FKPresentationRepositionProbeView.swift
//

import UIKit

/// An invisible probe view attached to the presentation host.
///
/// Purpose:
/// - Detect host layout size changes (`layoutSubviews`)
/// - Detect important trait changes (`traitCollectionDidChange`)
///
/// The probe itself never participates in interaction/visual rendering.
/// It only forwards change signals to `FKPresentationRepositionCoordinator`.
final class FKPresentationRepositionProbeView: UIView {
  /// Callback used by coordinator to react to host changes.
  /// - Parameters:
  ///   - didLayoutChange: Host bounds size changed.
  ///   - didTraitChange: Relevant trait values changed.
  var onHostLayoutOrTraitChange: ((_ didLayoutChange: Bool, _ didTraitChange: Bool) -> Void)?
  /// Cached size for layout-change diffing, so we only emit when size actually changed.
  private var lastBoundsSize: CGSize = .zero

  override init(frame: CGRect) {
    super.init(frame: frame)
    isHidden = true
    isUserInteractionEnabled = false
    lastBoundsSize = bounds.size
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let didLayoutChange = bounds.size != lastBoundsSize
    lastBoundsSize = bounds.size
    // Avoid noisy callbacks when layout pass happens but size stays the same.
    guard didLayoutChange else { return }
    onHostLayoutOrTraitChange?(true, false)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard let previousTraitCollection else { return }

    let didTraitChange =
      previousTraitCollection.horizontalSizeClass != traitCollection.horizontalSizeClass ||
      previousTraitCollection.verticalSizeClass != traitCollection.verticalSizeClass ||
      previousTraitCollection.userInterfaceStyle != traitCollection.userInterfaceStyle ||
      previousTraitCollection.displayScale != traitCollection.displayScale

    // Only emit when traits that can impact geometry/appearance actually changed.
    guard didTraitChange else { return }
    onHostLayoutOrTraitChange?(false, true)
  }
}
