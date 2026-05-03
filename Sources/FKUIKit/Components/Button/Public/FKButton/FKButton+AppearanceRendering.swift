import UIKit

extension FKButton {
  // MARK: - Appearance rendering

  func applyAppearanceForCurrentState() {
    let appearance = resolveAppearance()

    if isLoading {
      alpha = 1
      transform = .identity
    } else {
      let feedback = appearance.interaction.isHighlightFeedbackEnabled
      alpha = resolvedAlpha(for: appearance) * disabledVisualMultiplier()
      transform = (isHighlighted && feedback)
        ? CGAffineTransform(scaleX: appearance.interaction.pressedScale, y: appearance.interaction.pressedScale)
        : .identity
    }

    if let gradient = appearance.backgroundGradient {
      backgroundGradientLayer.isHidden = false
      backgroundGradientLayer.colors = gradient.colors.map(\.cgColor)
      if let locations = gradient.locations {
        backgroundGradientLayer.locations = locations.map { NSNumber(value: Double($0)) }
      } else {
        backgroundGradientLayer.locations = nil
      }
      backgroundGradientLayer.startPoint = gradient.startPoint
      backgroundGradientLayer.endPoint = gradient.endPoint
      backgroundColor = .clear
    } else {
      backgroundGradientLayer.isHidden = true
      backgroundColor = appearance.backgroundColor
    }
    layer.borderWidth = appearance.border.width
    layer.borderColor = appearance.border.color.cgColor
    layer.cornerCurve = appearance.cornerStyle.curve
    layer.maskedCorners = appearance.cornerStyle.maskedCorners
    applyCornerMetrics(using: appearance)
    
    if let shadow = appearance.shadow {
      layer.shadowOffset = shadow.offset
      layer.shadowRadius = shadow.radius
      layer.shadowOpacity = shadow.opacity
      layer.shadowColor = shadow.color.cgColor
      layer.masksToBounds = false
      updateShadowPath(using: appearance)
    } else {
      layer.shadowOpacity = 0
      layer.shadowPath = nil
      layer.masksToBounds = true
    }
    
    let insets = appearance.contentInsets
    topConstraint?.constant = insets.top
    leadingConstraint?.constant = insets.leading
    trailingConstraint?.constant = -insets.trailing
    bottomConstraint?.constant = -insets.bottom
    
    invalidateIntrinsicContentSize()
  }
  
  func applyCornerMetrics(using appearance: Appearance) {
    switch appearance.cornerStyle.corner {
    case .none:
      layer.cornerRadius = 0
    case let .fixed(radius):
      layer.cornerRadius = radius
    case .capsule:
      layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    if let clipsToBounds = appearance.clipsToBounds {
      self.clipsToBounds = clipsToBounds
    } else {
      self.clipsToBounds = (appearance.shadow == nil)
    }
  }

  /// Rebuilds `layer.shadowPath` from current bounds and corner settings when enabled.
  func updateShadowPath(using appearance: Appearance) {
    guard appearance.shadow != nil, appearance.shadowPathStrategy == .automatic else {
      layer.shadowPath = nil
      return
    }
    guard bounds.width > 0.5, bounds.height > 0.5 else {
      layer.shadowPath = nil
      return
    }
    layer.shadowPath = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: appearance.cornerStyle.maskedCorners.uiRectCorner,
      cornerRadii: CGSize(width: layer.cornerRadius, height: layer.cornerRadius)
    ).cgPath
  }

  func resolvedAlpha(for appearance: Appearance) -> CGFloat {
    let base = appearance.alpha
    let highlight = isHighlighted && isEnabled && appearance.interaction.isHighlightFeedbackEnabled
    if highlight {
      return base * appearance.interaction.pressedAlpha
    }
    return base
  }

  func activeImageElements() -> [ImageAttributes] {
    switch content.kind {
    case .imageOnly:
      return [resolveImageElement(for: .center)].compactMap { $0 }
    case let .textAndImage(alignment):
      switch alignment {
      case .leading:
        return [resolveImageElement(for: .leading)].compactMap { $0 }
      case .trailing:
        return [resolveImageElement(for: .trailing)].compactMap { $0 }
      case .bothSides:
        return [resolveImageElement(for: .leading), resolveImageElement(for: .trailing)].compactMap { $0 }
      }
    case .textOnly, .custom:
      return []
    }
  }
}

private extension CACornerMask {
  var uiRectCorner: UIRectCorner {
    var corners: UIRectCorner = []
    if contains(.layerMinXMinYCorner) { corners.insert(.topLeft) }
    if contains(.layerMaxXMinYCorner) { corners.insert(.topRight) }
    if contains(.layerMinXMaxYCorner) { corners.insert(.bottomLeft) }
    if contains(.layerMaxXMaxYCorner) { corners.insert(.bottomRight) }
    return corners
  }
}
