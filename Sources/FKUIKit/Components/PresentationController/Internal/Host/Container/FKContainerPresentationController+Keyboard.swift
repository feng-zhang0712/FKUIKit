import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Keyboard Observation

  /// Subscribes to keyboard frame updates once per presentation lifecycle.
  func startKeyboardTrackingIfNeeded() {
    guard configuration.keyboardAvoidance.isEnabled else { return }
    guard keyboardObservers.isEmpty else { return }

    let center = NotificationCenter.default
    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      Task { @MainActor [weak self] in
        self?.handleKeyboard(endFrameScreen: endFrameScreen, duration: duration, curveRaw: curveRaw)
      }
    })

    keyboardObservers.append(center.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let userInfo = note.userInfo ?? [:]
      let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
      let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
      let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
      Task { @MainActor [weak self] in
        self?.handleKeyboard(endFrameScreen: endFrameScreen, duration: duration, curveRaw: curveRaw)
      }
    })
  }

  /// Removes keyboard observers and restores any insets/transforms we touched.
  func stopKeyboardTracking() {
    let center = NotificationCenter.default
    for token in keyboardObservers {
      center.removeObserver(token)
    }
    keyboardObservers.removeAll()

    // Restore scroll insets if we changed them.
    if let scroll = findPrimaryScrollView(in: presentedViewController.view), let originalScrollInsets {
      scroll.contentInset = originalScrollInsets.content
      scroll.scrollIndicatorInsets = originalScrollInsets.indicator
    }
    originalScrollInsets = nil
    keyboardBottomInset = 0
    wrapperView.transform = .identity
  }

  // MARK: - Keyboard Application

  /// Converts keyboard frame to container space and updates cached inset.
  func handleKeyboard(endFrameScreen: CGRect, duration: Double, curveRaw: Int) {
    guard let containerView else { return }
    guard configuration.keyboardAvoidance.isEnabled else { return }

    let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))

    let endFrameInWindow = containerView.window?.convert(endFrameScreen, from: nil) ?? endFrameScreen
    let endFrame = containerView.convert(endFrameInWindow, from: containerView.window)

    let intersection = containerView.bounds.intersection(endFrame)
    let keyboardHeight = intersection.isNull ? 0 : intersection.height
    let safeBottom = containerView.safeAreaInsets.bottom
    let targetInset = max(0, keyboardHeight - safeBottom + configuration.keyboardAvoidance.additionalBottomInset)
    keyboardBottomInset = targetInset

    let animations: () -> Void = { [weak self] in
      self?.applyKeyboardAvoidance(in: containerView)
    }

    let strategy = configuration.keyboardAvoidance.strategy
    let shouldAnimate = (strategy == .interactive) ? true : duration > 0
    if shouldAnimate {
      UIView.animate(withDuration: duration, delay: 0, options: [options, .allowUserInteraction], animations: animations)
    } else {
      animations()
    }
  }

  /// Applies keyboard offset via either content insets or container translation.
  func applyKeyboardAvoidance(in containerView: UIView) {
    guard configuration.keyboardAvoidance.isEnabled else { return }

    switch configuration.keyboardAvoidance.strategy {
    case .disabled:
      return
    case .adjustContentInsets:
      guard let scroll = resolveKeyboardTargetScrollView() else { return }
      if originalScrollInsets == nil {
        originalScrollInsets = (scroll.contentInset, scroll.scrollIndicatorInsets)
      }
      var inset = originalScrollInsets?.content ?? scroll.contentInset
      inset.bottom = (originalScrollInsets?.content.bottom ?? 0) + keyboardBottomInset
      scroll.contentInset = inset
      var indicators = originalScrollInsets?.indicator ?? scroll.scrollIndicatorInsets
      indicators.bottom = (originalScrollInsets?.indicator.bottom ?? 0) + keyboardBottomInset
      scroll.scrollIndicatorInsets = indicators
    case .adjustContainer, .interactive:
      // Re-layout by shrinking available height for bottom/center modes.
      // We do this by temporarily translating the wrapper when it would overlap the keyboard.
      let keyboardTopY = containerView.bounds.height - keyboardBottomInset
      let overlap = max(0, wrapperView.frame.maxY - keyboardTopY)
      wrapperView.transform = CGAffineTransform(translationX: 0, y: -overlap)
    }
  }
}
