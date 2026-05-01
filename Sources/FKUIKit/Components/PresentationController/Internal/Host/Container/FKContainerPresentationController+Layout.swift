import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Container Layout

  /// Applies corner radius, border and shadow on the wrapper shell.
  func applyContainerAppearance() {
    containerBlurView.frame = wrapperView.bounds
    containerBlurView.maskedCornerRadius = configuration.cornerRadius
    wrapperView.layer.cornerRadius = configuration.cornerRadius
    wrapperView.layer.masksToBounds = true
    wrapperView.layer.shadowColor = configuration.shadow.color.cgColor
    wrapperView.layer.shadowOpacity = configuration.shadow.opacity
    wrapperView.layer.shadowRadius = configuration.shadow.radius
    wrapperView.layer.shadowOffset = configuration.shadow.offset
    wrapperView.layer.shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: configuration.cornerRadius).cgPath

    if configuration.border.isEnabled {
      wrapperView.layer.borderColor = configuration.border.color.cgColor
      wrapperView.layer.borderWidth = configuration.border.width
    } else {
      wrapperView.layer.borderWidth = 0
    }
  }

  /// Resolves container safe-area participation from selected policy.
  func containerSafeInsets(in containerView: UIView) -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea:
      return .zero
    case .containerRespectsSafeArea:
      return containerView.safeAreaInsets
    }
  }

  /// Lays out content container including safe-area and grabber offsets.
  func layoutContentContainer() {
    guard let containerView else {
      contentContainerView.frame = wrapperView.bounds
      return
    }

    if configuration.safeAreaPolicy == .contentRespectsSafeArea {
      let safe = containerView.safeAreaInsets
      let insets: UIEdgeInsets = {
        switch configuration.layout {
        case .bottomSheet(_):
          return .init(top: 0, left: 0, bottom: safe.bottom, right: 0)
        case .topSheet(_):
          return .init(top: safe.top, left: 0, bottom: 0, right: 0)
        case .center(_), .anchor:
          return safe
        case let .edge(edge):
          if edge.contains(.bottom) { return .init(top: 0, left: 0, bottom: safe.bottom, right: 0) }
          if edge.contains(.top) { return .init(top: safe.top, left: 0, bottom: 0, right: 0) }
          return safe
        }
      }()
      var frame = wrapperView.bounds.inset(by: insets)
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    } else {
      var frame = wrapperView.bounds
      frame = frame.inset(by: grabberContentInsets())
      frame = frame.inset(by: UIEdgeInsets(configuration.contentInsets))
      contentContainerView.frame = frame
    }

    layoutGrabber()
  }

  // MARK: - Grabber & Accessibility

  /// Computes extra content inset reserved for the grabber area.
  func grabberContentInsets() -> UIEdgeInsets {
    guard configuration.sheet.showsGrabber else { return .zero }
    let padding = configuration.sheet.grabberTopInset + configuration.sheet.grabberSize.height + 8
    switch configuration.layout {
    case .bottomSheet(_):
      return .init(top: padding, left: 0, bottom: 0, right: 0)
    case .topSheet(_):
      return .init(top: 0, left: 0, bottom: padding, right: 0)
    default:
      return .zero
    }
  }

  /// Adds/removes and styles grabber depending on active layout.
  func configureGrabberIfNeeded() {
    let showsGrabber: Bool
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      showsGrabber = configuration.sheet.showsGrabber
    default:
      showsGrabber = false
    }

    if showsGrabber {
      if grabberView.superview == nil {
        chromeView.addSubview(grabberView)
      }
      grabberView.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
      grabberView.layer.cornerRadius = configuration.sheet.grabberSize.height / 2
      grabberView.isHidden = false
    } else {
      grabberView.isHidden = true
      grabberView.removeFromSuperview()
    }
  }

  /// Configures accessibility labels/actions for backdrop and grabber affordances.
  func configureAccessibility() {
    backdropView.isAccessibilityElement = true
    backdropView.accessibilityTraits = [.button]
    backdropView.accessibilityLabel = configuration.accessibility.dismissLabel

    let dismissAction = UIAccessibilityCustomAction(name: configuration.accessibility.dismissActionName) { [weak self] _ in
      guard let self else { return false }
      self.presentedViewController.dismiss(animated: true)
      return true
    }
    backdropView.accessibilityCustomActions = [dismissAction]
    wrapperView.isAccessibilityElement = false

    if grabberView.superview != nil, !grabberView.isHidden {
      grabberView.isAccessibilityElement = true
      grabberView.accessibilityTraits = [.adjustable]
      grabberView.accessibilityLabel = configuration.accessibility.grabberLabel
      grabberView.accessibilityHint = configuration.accessibility.grabberHint
    }
  }

  /// Positions grabber near the interactive edge of the current layout.
  func layoutGrabber() {
    guard grabberView.superview != nil, !grabberView.isHidden else { return }
    let size = configuration.sheet.grabberSize
    let y: CGFloat = {
      if case .topSheet(_) = configuration.layout {
        return max(0, wrapperView.bounds.height - configuration.sheet.grabberTopInset - size.height)
      }
      return configuration.sheet.grabberTopInset
    }()
    grabberView.frame = CGRect(
      x: (wrapperView.bounds.width - size.width) / 2,
      y: y,
      width: size.width,
      height: size.height
    )
  }

  // MARK: - Detent Resolution

  /// Resolves current sheet height from active detent values.
  func resolvedSheetHeight(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    recalculateDetentsIfNeeded()
    if resolvedDetentHeights.indices.contains(currentDetentIndex) {
      return clampedContentHeight(resolvedDetentHeights[currentDetentIndex], containerView: containerView)
    }
    return clampedContentHeight(min(bounds.height * 0.5, max(240, measuredFitContentHeight(in: containerView))), containerView: containerView)
  }

  /// Recomputes all detent heights when geometry or content size changes.
  func recalculateDetentsIfNeeded() {
    guard let containerView else { return }
    let bounds = containerView.bounds
    let availableHeight = bounds.height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? (containerView.safeAreaInsets.top + containerView.safeAreaInsets.bottom) : 0)
    resolvedDetentHeights = configuration.sheet.detents.map { detent in
      resolve(detent: detent, availableHeight: availableHeight, containerView: containerView)
    }
    currentDetentIndex = max(0, min(currentDetentIndex, max(0, resolvedDetentHeights.count - 1)))
  }

  /// Maps a detent definition to a clamped concrete height.
  func resolve(detent: FKPresentationDetent, availableHeight: CGFloat, containerView: UIView) -> CGFloat {
    let value: CGFloat
    switch detent {
    case .fitContent:
      let maxHeight = availableHeight * configuration.sheet.maximumFitContentHeightFraction
      value = min(maxHeight, measuredFitContentHeight(in: containerView))
    case let .fixed(points):
      value = min(availableHeight, max(0, points))
    case let .fraction(fraction):
      value = min(availableHeight, max(0, fraction) * availableHeight)
    case .full:
      value = availableHeight
    }
    return clampedContentHeight(value, containerView: containerView)
  }

  /// Measures fit-content height using preferredContentSize then Auto Layout fitting.
  func measuredFitContentHeight(in containerView: UIView) -> CGFloat {
    let targetWidth = containerView.bounds.width
    let preferred = presentedViewController.preferredContentSize.height
    if preferred > 0 { return preferred }

    guard let view = hostedPresentedView else { return 360 }
    let size = view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return max(180, size.height)
  }

  // MARK: - Size Resolution

  /// Resolves center-layout frame with safe-area and margin clamping.
  func resolvedCenterFrame(in containerView: UIView, bounds: CGRect, safeInsets: UIEdgeInsets) -> CGRect {
    let margins = configuration.center.minimumMargins
    let maxWidth = bounds.width - (CGFloat(margins.leading + margins.trailing) + safeInsets.left + safeInsets.right)
    let maxHeight = bounds.height - (CGFloat(margins.top + margins.bottom) + safeInsets.top + safeInsets.bottom)

    let size: CGSize
    switch configuration.center.size {
    case let .fixed(fixed):
      size = .init(width: min(maxWidth, max(0, fixed.width)), height: min(maxHeight, max(0, fixed.height)))
    case let .fitted(maxSize):
      let contentW = max(220, presentedViewController.preferredContentSize.width)
      let contentH = max(220, measuredFitContentHeight(in: containerView))
      size = .init(
        width: min(maxWidth, min(maxSize.width, contentW)),
        height: min(maxHeight, min(maxSize.height, contentH))
      )
    }

    let originX = (bounds.width - size.width) / 2
    let originY = (bounds.height - size.height) / 2
    return CGRect(x: originX, y: originY, width: size.width, height: size.height)
  }

  /// Resolves sheet width from width policy and available bounds.
  func resolvedSheetWidth(in bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    let availableWidth = bounds.width - safeInsets.left - safeInsets.right
    switch configuration.sheet.widthPolicy {
    case .fill:
      return bounds.width
    case let .fraction(value):
      return min(availableWidth, max(220, availableWidth * min(max(value, 0.2), 1)))
    case let .max(value):
      return min(availableWidth, max(220, value))
    }
  }

  // MARK: - Edge Frame

  /// Computes fallback frame for edge-attached custom layouts.
  func edgeFrame(in bounds: CGRect, edge: UIRectEdge) -> CGRect {
    let width = min(bounds.width * 0.85, 420)
    let height = min(bounds.height * 0.85, 640)
    if edge.contains(.left) {
      return CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.right) {
      return CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.top) {
      return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
  }
}
