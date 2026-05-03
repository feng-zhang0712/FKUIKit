import UIKit

extension FKButton {
  // MARK: - Layout (UIControl overrides)

  open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    get { super.contentHorizontalAlignment }
    set {
      guard newValue != super.contentHorizontalAlignment else { return }
      super.contentHorizontalAlignment = newValue
      applyContentAlignmentLayout()
    }
  }

  open override var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
    get { super.contentVerticalAlignment }
    set {
      guard newValue != super.contentVerticalAlignment else { return }
      super.contentVerticalAlignment = newValue
      applyContentAlignmentLayout()
    }
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      applyContentAlignmentLayout()
    }
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      requestVisualRefresh()
    }
    if let previousTraitCollection,
       traitCollection.userInterfaceIdiom != previousTraitCollection.userInterfaceIdiom {
      syncPointerInteractionIfNeeded()
    }
  }

  /// Intrinsic size based on resolved content plus `Appearance.contentInsets`.
  open override var intrinsicContentSize: CGSize {
    let appearance = resolveAppearance()
    let insets = appearance.contentInsets
    let size = stackView.systemLayoutSizeFitting(
      CGSize(
        width: UIView.layoutFittingCompressedSize.width,
        height: UIView.layoutFittingCompressedSize.height
      ),
      withHorizontalFittingPriority: .defaultLow,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(
      width: size.width + insets.leading + insets.trailing,
      height: size.height + insets.top + insets.bottom
    )
  }
  
  /// Keeps corner radius and shadow path in sync with current bounds.
  open override func layoutSubviews() {
    super.layoutSubviews()
    let appearance = resolveAppearance()
    applyCornerMetrics(using: appearance)
    updateShadowPath(using: appearance)
    backgroundGradientLayer.frame = bounds
    backgroundGradientLayer.cornerRadius = layer.cornerRadius
    backgroundGradientLayer.cornerCurve = layer.cornerCurve
    backgroundGradientLayer.maskedCorners = layer.maskedCorners
  }
  
  /// Expands hit-testing using appearance, active image outsets, and `hitTestEdgeInsets`.
  open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    hitTestingBounds().contains(point)
  }
}
