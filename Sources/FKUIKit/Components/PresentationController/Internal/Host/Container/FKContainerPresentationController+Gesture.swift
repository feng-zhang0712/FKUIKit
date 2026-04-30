import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Gesture Installation

  /// Installs/removes outside-tap and pan gestures according to interaction policy.
  func installGesturesIfNeeded() {
    let allowsPassthrough = configuration.backgroundInteraction.isEnabled
    backdropView.isUserInteractionEnabled = !allowsPassthrough
    if allowsPassthrough, !configuration.backgroundInteraction.showsBackdropWhenEnabled {
      backdropView.isHidden = true
    } else {
      backdropView.isHidden = false
    }

    if !allowsPassthrough, configuration.dismissBehavior.allowsTapOutside, configuration.dismissBehavior.allowsBackdropTap {
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
      wrapperView.addGestureRecognizer(panToDismissGesture)
    } else {
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
    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: containerView)
    let velocity = recognizer.velocity(in: containerView)
    let trackedScrollView = resolvedTrackedScrollView()

    if recognizer.state == .began {
      if let scroll = trackedScrollView {
        let translationY = recognizer.translation(in: containerView).y
        if !shouldTransferPanFromScrollView(scroll, translationY: translationY) {
          isPanningSheet = false
          return
        }
      }
      isPanningSheet = true
      isInteractiveDismissing = false
      panStartFrame = wrapperView.frame
      dismissPanStartTranslationY = translation.y
    }

    guard isPanningSheet else { return }

    switch recognizer.state {
    case .began, .changed:
      if isInteractiveDismissing {
        let progress = interactiveDismissProgress(translationY: translation.y - dismissPanStartTranslationY, in: containerView)
        interactionController.updateDismissal(progress: progress)
        notifyProgress(progress)
        return
      }

      var frame = panStartFrame
      switch configuration.layout {
      case .bottomSheet(_):
        let safeInsets = containerSafeInsets(in: containerView)
        let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
        let bottomY = containerView.bounds.height - bottomExtra
        let minHeight = resolvedDetentHeights.min() ?? 240
        let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9

        if currentDetentIndex == 0, translation.y > 0 {
          frame.origin.y = panStartFrame.origin.y + translation.y
          frame.size.height = panStartFrame.size.height
        } else {
          frame.size.height = panStartFrame.size.height - translation.y
          frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
          frame.origin.y = bottomY - frame.size.height
        }
      case .topSheet(_):
        frame.size.height = max(0, panStartFrame.height - translation.y)
      default:
        break
      }

      let minY = sheetMinY(in: containerView)
      let maxY = sheetMaxY(in: containerView)
      switch configuration.layout {
      case .bottomSheet(_):
        frame.origin.y = min(max(frame.origin.y, minY - configuration.sheet.dismissThreshold), maxY + configuration.sheet.dismissThreshold)
      case .topSheet(_):
        let minHeight = resolvedDetentHeights.min() ?? 240
        let maxHeight = resolvedDetentHeights.max() ?? containerView.bounds.height * 0.9
        frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
        frame.origin.y = minY
      default:
        break
      }

      wrapperView.frame = frame
      chromeView.frame = wrapperView.bounds
      layoutContentContainer()
      hostedPresentedView?.frame = contentContainerView.bounds
      applyContainerAppearance()

      let progress = sheetDismissProgress(in: containerView)
      notifyProgress(progress)
      updateBackdropForCurrentState()

      if shouldEnterInteractiveDismiss(translationY: translation.y, velocityY: velocity.y) {
        isInteractiveDismissing = true
        dismissPanStartTranslationY = translation.y
        interactionController.beginDismissal(from: presentedViewController)
      }
    case .ended, .cancelled:
      isPanningSheet = false

      if isInteractiveDismissing {
        let progress = interactiveDismissProgress(translationY: translation.y - dismissPanStartTranslationY, in: containerView)
        let shouldFinish = progress > configuration.sheet.interactiveDismissProgressThreshold
          || abs(velocity.y) > configuration.sheet.dismissVelocityThreshold
        if shouldFinish {
          interactionController.finishDismissal()
          notifyProgress(1)
        } else {
          interactionController.cancelDismissal()
          notifyProgress(0)
          animateToCurrentDetent(animated: true)
        }
        isInteractiveDismissing = false
        return
      }

      let shouldDismiss = sheetShouldDismiss(translationY: translation.y, velocityY: velocity.y, in: containerView)
      if shouldDismiss {
        notifyProgress(1)
        presentedViewController.dismiss(animated: true)
        return
      }

      let targetIndex = nearestDetentIndex(for: wrapperView.frame, in: containerView, velocityY: velocity.y)
      setDetentIndex(targetIndex, animated: true)
      notifyProgress(0)
    default:
      break
    }
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
      let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.6
      let progress = (wrapperView.frame.height - maxHeight) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
    let progress = (sheetMaxY(in: containerView) - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
    return min(max(progress, 0), 1)
  }

  func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat, in containerView: UIView) -> Bool {
    guard configuration.dismissBehavior.allowsSwipe else { return false }
    switch configuration.layout {
    case .bottomSheet(_):
      if translationY > configuration.sheet.dismissThreshold { return true }
      if velocityY > configuration.sheet.dismissVelocityThreshold { return true }
    case .topSheet(_):
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
    let animations = {
      self.wrapperView.frame = targetFrame
      self.chromeView.frame = self.wrapperView.bounds
      self.layoutContentContainer()
      self.hostedPresentedView?.frame = self.contentContainerView.bounds
      self.applyContainerAppearance()
      self.updateBackdropForCurrentState()
    }
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: animations)
    } else {
      animations()
    }
  }

  func shouldTransferPanFromScrollView(_ scrollView: UIScrollView, translationY: CGFloat) -> Bool {
    let atTop = scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 0.5
    let maxOffsetY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
    let atBottom = scrollView.contentOffset.y >= maxOffsetY - 0.5

    switch configuration.layout {
    case .bottomSheet(_):
      return translationY > 0 ? atTop : false
    case .topSheet(_):
      return translationY < 0 ? atBottom : false
    default:
      return true
    }
  }

  func shouldEnterInteractiveDismiss(translationY: CGFloat, velocityY: CGFloat) -> Bool {
    switch configuration.layout {
    case .bottomSheet(_):
      let isAtLowestDetent = currentDetentIndex == 0
      return isAtLowestDetent && (translationY > configuration.sheet.dismissThreshold || velocityY > configuration.sheet.dismissVelocityThreshold)
    case .topSheet(_):
      let isAtLowestDetent = currentDetentIndex == 0
      return isAtLowestDetent && (translationY < -configuration.sheet.dismissThreshold || velocityY < -configuration.sheet.dismissVelocityThreshold)
    default:
      return false
    }
  }

  func interactiveDismissProgress(translationY: CGFloat, in containerView: UIView) -> CGFloat {
    let denominator = max(containerView.bounds.height * 0.28, 120)
    let raw: CGFloat
    switch configuration.layout {
    case .bottomSheet(_):
      raw = translationY / denominator
    case .topSheet(_):
      raw = -translationY / denominator
    default:
      raw = abs(translationY) / denominator
    }
    return min(max(raw, 0), 1)
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
