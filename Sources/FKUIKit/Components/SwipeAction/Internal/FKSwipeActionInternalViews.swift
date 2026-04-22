import ObjectiveC
import UIKit

// MARK: - Association Keys

enum FKSwipeAssociationKey {
  // Associated object key for per-cell button holder view.
  nonisolated(unsafe) static var holder: UInt8 = 0
}

// MARK: - View helpers

extension UIView {
  func isDescendant(ofClassNamed name: String) -> Bool {
    // Traverse superviews to avoid stealing taps from internal action button views.
    var v: UIView? = self
    while let current = v {
      if String(describing: type(of: current)) == name { return true }
      v = current.superview
    }
    return false
  }
}

extension Array {
  // NOTE:
  // This project already provides `Array[subscript(safe:)]` in `FKUIKit/Core/Extensions/Array.swift`.
  // Keep this file focused on SwipeAction internal views only.
}

// MARK: - Buttons Holder

/// A lightweight container inserted below cell content view.
///
/// This view is intentionally frame-based (no Auto Layout) to minimize layout overhead during pan.
@MainActor
final class FKSwipeButtonsHolder: UIView {
  // Cached button models for both sides.
  private var leftButtons: [FKSwipeActionButton] = []
  private var rightButtons: [FKSwipeActionButton] = []
  // Rendered UIControl views corresponding to button models.
  private var leftViews: [FKSwipeActionButtonView] = []
  private var rightViews: [FKSwipeActionButtonView] = []
  // Tap forwarder to the manager. Includes actionID and optional handler.
  private var onTap: ((String, (@Sendable () -> Void)?) -> Void)?

  func configure(
    left: [FKSwipeActionButton],
    right: [FKSwipeActionButton],
    onTap: @escaping (String, (@Sendable () -> Void)?) -> Void
  ) {
    // Store callback and rebuild views only when identity changes.
    self.onTap = onTap

    // Rebuild only when identity changes to avoid view churn during frequent swipes.
    if leftButtons.map(\.id) != left.map(\.id) || rightButtons.map(\.id) != right.map(\.id) {
      leftButtons = left
      rightButtons = right
      rebuild()
    } else {
      leftButtons = left
      rightButtons = right
    }
  }

  func updateLayout(contentTranslationX: CGFloat) {
    // Layout buttons for both sides with fixed widths; height matches cell height.
    let h = bounds.height

    var x: CGFloat = 0
    for (idx, btn) in leftButtons.enumerated() {
      let w = max(0, btn.width)
      leftViews[safe: idx]?.frame = CGRect(x: x, y: 0, width: w, height: h)
      x += w
    }

    let rightTotal = rightButtons.reduce(CGFloat(0)) { $0 + max(0, $1.width) }
    x = bounds.width - rightTotal
    for (idx, btn) in rightButtons.enumerated() {
      let w = max(0, btn.width)
      rightViews[safe: idx]?.frame = CGRect(x: x, y: 0, width: w, height: h)
      x += w
    }

    // Simple visibility optimization: keep off-screen side hidden to reduce blending work.
    let showLeft = contentTranslationX > 1
    let showRight = contentTranslationX < -1
    leftViews.forEach { $0.isHidden = !showLeft }
    rightViews.forEach { $0.isHidden = !showRight }
  }

  private func rebuild() {
    // Fully rebuild button subviews when identity changes.
    subviews.forEach { $0.removeFromSuperview() }
    leftViews = leftButtons.map(makeView(button:))
    rightViews = rightButtons.map(makeView(button:))
    leftViews.forEach(addSubview)
    rightViews.forEach(addSubview)
  }

  private func makeView(button: FKSwipeActionButton) -> FKSwipeActionButtonView {
    // Construct a UIControl from the value-based model.
    let v = FKSwipeActionButtonView(model: button)
    v.onTap = { [weak self] in
      self?.onTap?(button.id, button.handler)
    }
    return v
  }
}

