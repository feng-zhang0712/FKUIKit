import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Gesture Installation

  /// Installs/removes outside-tap and pan gestures according to interaction policy.
  func installGesturesIfNeeded() {
    let allowsPassthrough: Bool = {
      if configuration.backgroundInteraction.isEnabled { return true }
      if case let .dim(_, alpha) = configuration.backdropStyle, alpha <= 0 {
        return configuration.zeroDimBackdropBehavior == .passthrough
      }
      return false
    }()
    backdropView.isUserInteractionEnabled = !allowsPassthrough
    if allowsPassthrough, !configuration.backgroundInteraction.showsBackdropWhenEnabled {
      backdropView.isHidden = true
    } else {
      backdropView.isHidden = false
    }

    let allowsBackdropTapDismiss: Bool = {
      guard configuration.dismissBehavior.allowsTapOutside, configuration.dismissBehavior.allowsBackdropTap else { return false }
      if case let .dim(_, alpha) = configuration.backdropStyle, alpha <= 0 {
        return configuration.zeroDimBackdropBehavior == .dismissable
      }
      return true
    }()

    if !allowsPassthrough, allowsBackdropTapDismiss {
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.removeGestureRecognizer(tapToDismissGesture)
    }

    let allowsSwipe: Bool = {
      if case .center(_) = configuration.layout { return configuration.center.dismissEnabled }
      return configuration.dismissBehavior.allowsSwipe
    }()

    if allowsSwipe {
      panToDismissGesture.maximumNumberOfTouches = 1
      panToDismissGesture.delegate = self
      panToDismissGesture.cancelsTouchesInView = false
      wrapperView.addGestureRecognizer(panToDismissGesture)
    } else {
      panToDismissGesture.delegate = nil
      wrapperView.removeGestureRecognizer(panToDismissGesture)
    }
  }

  // MARK: - Gesture Handlers

  /// Handles backdrop taps for tap-outside dismissal.
  @objc func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    presentedViewController.dismiss(animated: true)
  }

  /// Routes pan gesture to center or sheet interaction handlers.
  @objc func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    guard let containerView else { return }

    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      handleSheetPan(recognizer, in: containerView)
    case .center(_):
      handleCenterPan(recognizer, in: containerView)
    default:
      break
    }
  }

  /// Tracks vertical drag progress for center layouts and decides finish/cancel.
  func handleCenterPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    guard configuration.center.dismissEnabled else { return }
    let translation = recognizer.translation(in: containerView)
    let progress = min(max(abs(translation.y) / max(1, containerView.bounds.height * 0.4), 0), 1)
    notifyProgress(progress)
    let velocityY = abs(recognizer.velocity(in: containerView).y)

    if recognizer.state == .ended || recognizer.state == .cancelled {
      if progress > configuration.center.dismissProgressThreshold || velocityY > configuration.center.dismissVelocityThreshold {
        presentedViewController.dismiss(animated: true)
      } else {
        notifyProgress(0)
      }
    }
  }

  /// Drives sheet detent interpolation and interactive dismiss transitions.
  func handleSheetPan(_ recognizer: UIPanGestureRecognizer, in containerView: UIView) {
    let frameProvider: ((CGFloat) -> CGRect)?
    switch configuration.layout {
    case .bottomSheet(_):
      frameProvider = { [weak self] translationY in
        guard let self else { return .zero }
        return self.interactiveBottomSheetFrame(in: containerView, translationY: translationY)
      }
    case .topSheet(_):
      frameProvider = { [weak self] translationY in
        guard let self else { return .zero }
        return self.interactiveTopSheetFrame(in: containerView, translationY: translationY)
      }
    default:
      frameProvider = nil
    }
    guard let frameProvider else { return }

    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: containerView)
    let velocity = recognizer.velocity(in: containerView)
    let trackedScrollView = resolvedTrackedScrollView()

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      panStartFrame = wrapperView.frame
      sheetPanVelocityY = 0
      if let trackedScrollView {
        trackedScrollView.panGestureRecognizer.isEnabled = true
      }

    case .changed:
      guard isPanningSheet else { return }
      sheetPanVelocityY = velocity.y

      if let trackedScrollView, !shouldTransferPanFromScrollView(trackedScrollView, translationY: translation.y) {
        // Let inner scroll own this direction while keeping sheet stable.
        animateToCurrentDetent(animated: false)
        return
      }

      let frame = frameProvider(translation.y)
      applyInteractiveFrame(frame)
      notifyProgress(sheetDismissProgress(in: containerView))
      updateBackdropForCurrentState()

    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false

      if sheetShouldDismiss(translationY: translation.y, velocityY: velocity.y, in: containerView) {
        notifyProgress(1)
        keepsInteractiveFrameForDismissal = true
        dismissalStartingFrame = wrapperView.frame
        presentedViewController.dismiss(animated: true)
        sheetPanVelocityY = 0
        return
      }

      let targetIndex = nearestDetentIndex(for: wrapperView.frame, in: containerView, velocityY: velocity.y)
      setDetentIndex(targetIndex, animated: true)
      notifyProgress(0)
      sheetPanVelocityY = 0

    default:
      break
    }
  }

  func interactiveBottomSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    var frame = panStartFrame
    let safeInsets = containerSafeInsets(in: containerView)
    let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    let bottomY = containerView.bounds.height - bottomExtra
    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9

    if currentDetentIndex == 0, translationY > 0 {
      // System-like behavior: at smallest detent, downward drag follows panel translation.
      frame.origin.y = panStartFrame.origin.y + translationY
      frame.size.height = panStartFrame.size.height
    } else {
      // Upward drag expands, downward drag contracts toward the next smaller detent.
      frame.size.height = panStartFrame.height - translationY
      frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
      frame.origin.y = bottomY - frame.size.height
    }

    let minY = sheetMinY(in: containerView)
    let maxY = sheetMaxY(in: containerView)
    if currentDetentIndex == 0, translationY > 0 {
      // At smallest detent, downward drag is dismiss / off-screen follow-through. Do not cap at
      // `maxY + dismissThreshold` (~44pt) or the sheet stops moving while the finger keeps going
      // (feels "stuck"), then often snaps back on release.
      frame.origin.y = max(frame.origin.y, minY - configuration.sheet.dismissThreshold)
    } else {
      frame.origin.y = min(max(frame.origin.y, minY - configuration.sheet.dismissThreshold), maxY + configuration.sheet.dismissThreshold)
    }
    return frame
  }

  func applyInteractiveFrame(_ frame: CGRect) {
    wrapperView.frame = frame
    chromeView.frame = wrapperView.bounds
    layoutContentContainer()
    hostedPresentedView?.frame = contentContainerView.bounds
    applyContainerAppearance()
  }

  // MARK: - Top Sheet (mirror of bottom sheet, vertical axis inverted)

  func interactiveTopSheetFrame(in containerView: UIView, translationY: CGFloat) -> CGRect {
    var frame = panStartFrame
    let minY = sheetMinY(in: containerView)
    let maxY = sheetMaxY(in: containerView)
    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9

    if currentDetentIndex == 0, translationY < 0 {
      // Smallest detent: upward drag moves the panel off the top (dismiss), height unchanged.
      frame.origin.y = panStartFrame.origin.y + translationY
      frame.size.height = panStartFrame.size.height
    } else {
      // Top sheet expands downward: finger down increases height; finger up decreases height.
      // Top edge stays pinned at `minY` while changing detents.
      frame.size.height = panStartFrame.height + translationY
      frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
      frame.origin.y = minY
    }

    if currentDetentIndex == 0, translationY < 0 {
      // Do not cap upward dismiss travel to ~44pt; allow following the finger off-screen.
      frame.origin.y = min(frame.origin.y, minY)
    } else {
      frame.origin.y = min(max(frame.origin.y, minY - configuration.sheet.dismissThreshold), maxY + configuration.sheet.dismissThreshold)
    }
    return frame
  }

  // MARK: - Sheet Interaction Helpers

  func sheetMinY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    if case .topSheet(_) = configuration.layout {
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    }
    let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.5
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - maxHeight - extra
  }

  func sheetMaxY(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    if case .topSheet(_) = configuration.layout {
      return configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
    }
    let minHeight = resolvedDetentHeights.min() ?? 240
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    return bounds.height - minHeight - extra
  }

  func sheetDismissProgress(in containerView: UIView) -> CGFloat {
    let bounds = containerView.bounds
    if case .topSheet(_) = configuration.layout {
      let minY = sheetMinY(in: containerView)
      let progress = (minY - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
    let progress = (sheetMaxY(in: containerView) - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
    return min(max(progress, 0), 1)
  }

  func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat, in containerView: UIView) -> Bool {
    guard configuration.dismissBehavior.allowsSwipe else { return false }
    switch configuration.layout {
    case .bottomSheet(_):
      // Match system sheet: swipe-to-dismiss only from the smallest detent. Larger detents
      // must shrink via detent snapping first; otherwise any downward translation/velocity
      // would dismiss instead of stopping at intermediate detents.
      guard currentDetentIndex == 0 else { return false }
      if translationY > configuration.sheet.dismissThreshold { return true }
      if velocityY > configuration.sheet.dismissVelocityThreshold { return true }
    case .topSheet(_):
      guard currentDetentIndex == 0 else { return false }
      if translationY < -configuration.sheet.dismissThreshold { return true }
      if velocityY < -configuration.sheet.dismissVelocityThreshold { return true }
    default:
      break
    }
    return false
  }

  func nearestDetentIndex(for frame: CGRect, in containerView: UIView, velocityY: CGFloat) -> Int {
    let bounds = containerView.bounds
    let safeInsets = containerSafeInsets(in: containerView)
    let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? (safeInsets.top + safeInsets.bottom) : 0
    let availableHeight = bounds.height - extra

    let currentHeight: CGFloat
    switch configuration.layout {
    case .bottomSheet(_):
      let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      currentHeight = bounds.height - frame.minY - bottomExtra
    case .topSheet(_):
      currentHeight = frame.height
    default:
      currentHeight = min(availableHeight, max(0, frame.height))
    }

    if abs(velocityY) > 900, resolvedDetentHeights.count >= 2 {
      switch configuration.layout {
      case .bottomSheet(_):
        return velocityY < 0 ? min(resolvedDetentHeights.count - 1, currentDetentIndex + 1) : max(0, currentDetentIndex - 1)
      case .topSheet(_):
        // Finger down (positive vy) expands toward larger detent; finger up shrinks.
        return velocityY > 0 ? min(resolvedDetentHeights.count - 1, currentDetentIndex + 1) : max(0, currentDetentIndex - 1)
      default:
        break
      }
    }

    if configuration.sheet.enablesMagneticSnapping {
      for (idx, h) in resolvedDetentHeights.enumerated() where abs(h - currentHeight) <= configuration.sheet.magneticSnapThreshold {
        return idx
      }
    }

    var best = 0
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (idx, h) in resolvedDetentHeights.enumerated() {
      let d = abs(h - currentHeight)
      if d < bestDistance {
        bestDistance = d
        best = idx
      }
    }
    return best
  }

  func setDetentIndex(_ index: Int, animated: Bool) {
    let clamped = max(0, min(index, max(0, resolvedDetentHeights.count - 1)))
    if clamped == currentDetentIndex { animateToCurrentDetent(animated: animated); return }
    currentDetentIndex = clamped
    if configuration.sheet.detents.indices.contains(clamped) {
      notifyDetentDidChange(configuration.sheet.detents[clamped], index: clamped)
      if configuration.haptics.isEnabled {
        let generator = UIImpactFeedbackGenerator(style: configuration.haptics.feedbackStyle)
        generator.impactOccurred()
      }
    }
    animateToCurrentDetent(animated: animated)
  }

  func setDetent(_ detent: FKPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(where: { $0 == detent }) else { return }
    setDetentIndex(index, animated: animated)
  }

  func animateToCurrentDetent(animated: Bool) {
    guard containerView != nil else { return }
    let targetFrame = frameOfPresentedViewInContainerView
    let distance = max(
      1,
      abs(wrapperView.frame.minY - targetFrame.minY),
      abs(wrapperView.frame.height - targetFrame.height)
    )
    let animations = {
      self.wrapperView.frame = targetFrame
      self.chromeView.frame = self.wrapperView.bounds
      self.layoutContentContainer()
      self.hostedPresentedView?.frame = self.contentContainerView.bounds
      self.applyContainerAppearance()
      self.updateBackdropForCurrentState()
    }
    if animated {
      let velocityVector = CGVector(dx: 0, dy: sheetPanVelocityY / distance)
      let softenedVelocity = CGVector(dx: 0, dy: velocityVector.dy * 0.75)
      let timing = UISpringTimingParameters(dampingRatio: 0.86, initialVelocity: softenedVelocity)
      let animator = UIViewPropertyAnimator(duration: 0.42, timingParameters: timing)
      animator.addAnimations(animations)
      animator.startAnimation()
    } else {
      animations()
    }
  }

  func shouldTransferPanFromScrollView(_ scrollView: UIScrollView, translationY: CGFloat) -> Bool {
    if abs(translationY) < 0.5 { return true }
    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5

    switch configuration.layout {
    case .bottomSheet(_):
      let canExpandToLargerDetent = currentDetentIndex < max(0, resolvedDetentHeights.count - 1)
      if translationY < 0 {
        // Upward drag should prioritize detent expansion.
        return canExpandToLargerDetent || atTop
      }
      // Downward: at smallest detent this is dismiss/rubber-band — sheet must own the gesture.
      if currentDetentIndex == 0 {
        return true
      }
      // Larger detent: let inner scroll consume until scrolled to top, then sheet shrinks.
      return atTop
    case .topSheet(_):
      let canExpandToLargerDetent = currentDetentIndex < max(0, resolvedDetentHeights.count - 1)
      if translationY > 0 {
        // Finger down expands top sheet toward larger detents.
        return canExpandToLargerDetent || atTop
      }
      // Finger up shrinks; at smallest detent it's dismiss / rubber-band — sheet owns it.
      if currentDetentIndex == 0 {
        return true
      }
      // Larger detent: let inner scroll consume until scrolled to bottom, then sheet shrinks.
      return atBottom
    default:
      return true
    }
  }

  func clampedContentHeight(_ height: CGFloat, containerView: UIView) -> CGFloat {
    var value = max(0, height)
    if let minimum = configuration.sheet.minimumContentHeight {
      value = max(value, minimum)
    }
    if let maximum = configuration.sheet.maximumContentHeight {
      value = min(value, maximum)
    }
    let safe = containerSafeInsets(in: containerView)
    let maxAvailable = containerView.bounds.height - safe.top - safe.bottom
    return min(value, maxAvailable)
  }
}

// MARK: - Gesture Delegate

@MainActor
extension FKContainerPresentationController {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let containerView else { return true }
    let velocity = pan.velocity(in: containerView)
    return abs(velocity.y) >= abs(velocity.x)
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard gestureRecognizer === panToDismissGesture || otherGestureRecognizer === panToDismissGesture else { return false }
    return otherGestureRecognizer.view is UIScrollView || gestureRecognizer.view is UIScrollView
  }
}
