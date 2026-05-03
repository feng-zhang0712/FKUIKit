import UIKit

extension FKButton {
  open override func sendActions(for controlEvents: UIControl.Event) {
    guard !isLoading else { return }
    currentlySendingControlEvents = controlEvents
    defer { currentlySendingControlEvents = [] }
    if shouldSuppressThrottledPrimaryAction(for: controlEvents) {
      return
    }
    if controlEvents.contains(.primaryActionTriggered) || controlEvents.contains(.touchUpInside) {
      emitInteractionFeedback(for: .primaryAction)
    }
    super.sendActions(for: controlEvents)
  }

  open override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
    guard !isLoading else { return }
    // Some UIKit dispatch paths call `sendAction` directly and skip `sendActions(for:)`.
    // In that case, default to primary-action semantics so tap throttling still works.
    let effectiveEvents: UIControl.Event = currentlySendingControlEvents.isEmpty ? [.touchUpInside] : currentlySendingControlEvents
    if shouldSuppressThrottledPrimaryAction(for: effectiveEvents, event: event) { return }
    super.sendAction(action, to: target, for: event)
  }

  open override func sendAction(_ action: UIAction) {
    guard !isLoading else { return }
    // `addAction(_:for:)` / UIAction dispatch commonly uses this overload without a `UIEvent`.
    let effectiveEvents: UIControl.Event = currentlySendingControlEvents.isEmpty ? [.touchUpInside] : currentlySendingControlEvents
    if shouldSuppressThrottledPrimaryAction(for: effectiveEvents, event: nil) { return }
    super.sendAction(action)
  }

  // MARK: - Primary-action throttling

  func shouldSuppressThrottledPrimaryAction(for controlEvents: UIControl.Event) -> Bool {
    let isPrimary = controlEvents.contains(.primaryActionTriggered) || controlEvents.contains(.touchUpInside)
    guard isPrimary else { return false }
    return shouldSuppressThrottledPrimaryAction(for: controlEvents, event: nil)
  }

  /// Returns `true` if this dispatch should be dropped due to `minimumTapInterval`.
  /// Throttling applies to primary actions only (`.primaryActionTriggered` / `.touchUpInside`).
  func shouldSuppressThrottledPrimaryAction(for controlEvents: UIControl.Event, event: UIEvent?) -> Bool {
    guard minimumTapInterval > 0 else { return false }
    let isPrimary = controlEvents.contains(.primaryActionTriggered) || controlEvents.contains(.touchUpInside)
    guard isPrimary else { return false }
    let now = CFAbsoluteTimeGetCurrent()

    if let event, event.type == .touches || event.type == .presses {
      let wave = event.timestamp
      if wave == lastThrottledInteractionEventTimestamp {
        return false
      }
      if lastPrimaryActionDeliveryTime > 0, now - lastPrimaryActionDeliveryTime < minimumTapInterval {
        return true
      }
      lastThrottledInteractionEventTimestamp = wave
      lastPrimaryActionDeliveryTime = now
      return false
    }

    if event == nil {
      if lastPrimaryActionDeliveryTime > 0, now - lastPrimaryActionDeliveryTime < minimumTapInterval {
        return true
      }
      lastPrimaryActionDeliveryTime = now
      return false
    }

    return false
  }
}
