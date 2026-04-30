import UIKit

@MainActor
extension FKContainerPresentationController {
  // MARK: - Scroll Resolution

  /// Depth-first lookup for the first scroll view in presented content.
  func findPrimaryScrollView(in root: UIView?) -> UIScrollView? {
    guard let root else { return nil }
    if let scroll = root as? UIScrollView { return scroll }
    for sub in root.subviews {
      if let found = findPrimaryScrollView(in: sub) { return found }
    }
    return nil
  }

  /// Resolves keyboard inset target: explicit configuration first, fallback to first discovered scroll view.
  func resolveKeyboardTargetScrollView() -> UIScrollView? {
    if let explicit = configuration.keyboardAvoidance.targetScrollView?.object {
      return explicit
    }
    return findPrimaryScrollView(in: presentedViewController.view)
  }

  /// Resolves the sheet pan-handoff scroll view based on selected strategy.
  func resolvedTrackedScrollView() -> UIScrollView? {
    switch configuration.sheet.scrollTrackingStrategy {
    case .automatic:
      return findPrimaryScrollView(in: presentedViewController.view)
    case .disabled:
      return nil
    case let .explicit(box):
      return box.object
    }
  }
}
