import UIKit

extension FKButton {
  // MARK: - Content layout (stack composition)

  func applyContentLayout() {
    switch content.kind {
    case .textOnly, .imageOnly, .custom:
      stackView.spacing = 0
    case .textAndImage:
      break
    }
    
    let desired = desiredArrangedSubviewsForCurrentContent()
    let current = stackView.arrangedSubviews
    if current.count == desired.count && zip(current, desired).allSatisfy({ $0 === $1 }) {
      return
    }

    // Remove only views that are no longer needed for this content shape.
    for view in current where !desired.contains(where: { $0 === view }) {
      stackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    // Keep existing arranged subviews and only move/insert when required.
    for (targetIndex, view) in desired.enumerated() {
      if let existingIndex = stackView.arrangedSubviews.firstIndex(where: { $0 === view }) {
        if existingIndex != targetIndex {
          stackView.removeArrangedSubview(view)
          stackView.insertArrangedSubview(view, at: targetIndex)
        }
      } else {
        stackView.insertArrangedSubview(view, at: targetIndex)
      }
    }
  }

  func desiredArrangedSubviewsForCurrentContent() -> [UIView] {
    switch content.kind {
    case .textOnly:
      return [titleContainerViewIfNeeded()]
    case .imageOnly:
      return [imageViewIfNeeded(for: .center)]
    case .textAndImage(let alignment):
      switch alignment {
      case .leading:
        return [imageViewIfNeeded(for: .leading), titleContainerViewIfNeeded()]
      case .trailing:
        return [titleContainerViewIfNeeded(), imageViewIfNeeded(for: .trailing)]
      case .bothSides:
        return [imageViewIfNeeded(for: .leading), titleContainerViewIfNeeded(), imageViewIfNeeded(for: .trailing)]
      }
    case .custom:
      return [customContentHostIfNeeded()]
    }
  }
}
