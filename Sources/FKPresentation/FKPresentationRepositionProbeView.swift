//
// FKPresentationRepositionProbeView.swift
//

import UIKit

final class FKPresentationRepositionProbeView: UIView {
  var onHostLayoutOrTraitChange: ((_ didLayoutChange: Bool, _ didTraitChange: Bool) -> Void)?
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

    guard didTraitChange else { return }
    onHostLayoutOrTraitChange?(false, true)
  }
}
