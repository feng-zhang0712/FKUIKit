import UIKit

@MainActor
internal final class FKAnchoredDropdownContentContainerViewController: UIViewController {
  enum Transition {
    case none
    case crossfade(duration: TimeInterval)
    case slideVertical(direction: SlideDirection, duration: TimeInterval)

    enum SlideDirection {
      case up
      case down
    }
  }

  private(set) var isTransitioningContent: Bool = false
  private var current: UIViewController?
  var onPreferredContentSizeDidChange: (() -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  func setContent(_ content: UIViewController, transition: Transition, completion: (() -> Void)? = nil) {
    // If content is already displayed, treat as no-op.
    if current === content {
      preferredContentSize = content.preferredContentSize
      completion?()
      return
    }

    let previous = current
    isTransitioningContent = true

    addChild(content)
    content.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(content.view)
    NSLayoutConstraint.activate([
      content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      content.view.topAnchor.constraint(equalTo: view.topAnchor),
      content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    view.layoutIfNeeded()

    // Publish the target size immediately so the host can animate frame changes in parallel
    // with content transition (instead of waiting until transition completion).
    preferredContentSize = resolvedPreferredContentSize(for: content)
    onPreferredContentSizeDidChange?()

    let finalize: () -> Void = { [weak self] in
      guard let self else { return }
      previous?.willMove(toParent: nil)
      previous?.view.removeFromSuperview()
      previous?.removeFromParent()

      content.didMove(toParent: self)
      self.current = content
      self.isTransitioningContent = false
      self.preferredContentSize = self.resolvedPreferredContentSize(for: content)
      self.onPreferredContentSizeDidChange?()
      completion?()
    }

    guard let previous else {
      // If no previous content, finalize immediately.
      finalize()
      return
    }
    if case .none = transition {
      finalize()
      return
    }

    previous.willMove(toParent: nil)

    switch transition {
    case .none:
      finalize()

    case let .crossfade(duration):
      content.view.alpha = 0
      UIView.animate(withDuration: max(0, duration), delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
        content.view.alpha = 1
        previous.view.alpha = 0
      } completion: { _ in
        previous.view.alpha = 1
        finalize()
      }

    case let .slideVertical(direction, duration):
      let h = max(1, view.bounds.height)
      let offset: CGFloat = (direction == .up) ? h : -h
      content.view.transform = CGAffineTransform(translationX: 0, y: offset)
      UIView.animate(withDuration: max(0, duration), delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
        content.view.transform = .identity
        previous.view.transform = CGAffineTransform(translationX: 0, y: -offset * 0.35)
        previous.view.alpha = 0
      } completion: { _ in
        previous.view.transform = .identity
        previous.view.alpha = 1
        finalize()
      }
    }
  }

  override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
    super.preferredContentSizeDidChange(forChildContentContainer: container)
    guard let current, container === current else { return }
    preferredContentSize = current.preferredContentSize
    onPreferredContentSizeDidChange?()
  }

  private func resolvedPreferredContentSize(for content: UIViewController) -> CGSize {
    let preferred = content.preferredContentSize
    if preferred.height > 0 {
      return preferred
    }
    let targetWidth = max(1, view.bounds.width)
    let measured = content.view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(width: preferred.width, height: max(1, measured.height))
  }
}
