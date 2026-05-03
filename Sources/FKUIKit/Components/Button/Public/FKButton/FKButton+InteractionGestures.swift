import UIKit

extension FKButton {
  // MARK: - Hit testing

  func hitTestingBounds() -> CGRect {
    let appearanceOutsets = resolveAppearance().interaction.hitTestOutsets
    let imageOutsets = activeImageElements().reduce(UIEdgeInsets.zero) { current, element in
      UIEdgeInsets(
        top: max(current.top, element.hitTestOutsets.top),
        left: max(current.left, element.hitTestOutsets.left),
        bottom: max(current.bottom, element.hitTestOutsets.bottom),
        right: max(current.right, element.hitTestOutsets.right)
      )
    }
    let sum = UIEdgeInsets(
      top: appearanceOutsets.top + imageOutsets.top,
      left: appearanceOutsets.left + imageOutsets.left,
      bottom: appearanceOutsets.bottom + imageOutsets.bottom,
      right: appearanceOutsets.right + imageOutsets.right
    )
    let inset = UIEdgeInsets(
      top: -sum.top + hitTestEdgeInsets.top,
      left: -sum.left + hitTestEdgeInsets.left,
      bottom: -sum.bottom + hitTestEdgeInsets.bottom,
      right: -sum.right + hitTestEdgeInsets.right
    )
    return bounds.inset(by: inset)
  }

  func disabledVisualMultiplier() -> CGFloat {
    guard !isLoading else { return 1 }
    guard !isEnabled, automaticallyDimsWhenDisabled else { return 1 }
    return max(0, min(1, disabledDimmingAlpha))
  }

  // MARK: - Long press

  @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    switch sender.state {
    case .began:
      onLongPressBegan?()
      onLongPressRepeatTick?()
      guard onLongPressRepeatTick != nil, longPressRepeatTickInterval > 0 else { break }
      longPressRepeatTimer?.invalidate()
      let timer = Timer(timeInterval: longPressRepeatTickInterval, repeats: true) { [weak self] _ in
        self?.onLongPressRepeatTick?()
      }
      RunLoop.main.add(timer, forMode: .common)
      longPressRepeatTimer = timer
    case .ended, .cancelled, .failed:
      longPressRepeatTimer?.invalidate()
      longPressRepeatTimer = nil
      onLongPressEnded?()
    default:
      break
    }
  }
}
