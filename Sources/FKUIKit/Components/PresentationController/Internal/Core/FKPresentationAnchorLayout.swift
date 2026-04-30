import UIKit

// MARK: - Shared anchor layout (anchor-hosted)

/// Shared anchor frame resolver used by both modal and anchor-hosted modes.
@MainActor
enum FKPresentationAnchorLayout {
  struct Result {
    var frame: CGRect
    var sourceRect: CGRect?
    var resolvedDirection: FKAnchor.Direction
  }

  static func resolveSourceRect(in containerView: UIView, anchor: FKAnchor) -> CGRect? {
    switch anchor.source {
    case let .view(box):
      guard let view = box.object else { return nil }
      guard view.window != nil else { return nil }
      // Convert to the host/container coordinate space so modal and anchor-hosted paths share identical
      // geometry decisions even when the anchor is deeply nested.
      return view.convert(view.bounds, to: containerView)
    case let .rect(provider):
      return provider()
    }
  }

  static func anchoredFrame(
    in containerView: UIView,
    bounds: CGRect,
    safeInsets: UIEdgeInsets,
    anchor: FKAnchor,
    measuredContentHeight: () -> CGFloat
  ) -> Result {
    guard let sourceRect = resolveSourceRect(in: containerView, anchor: anchor) else {
      // Fallback to center when anchor cannot be resolved yet (detached view / stale weak reference).
      let width = min(bounds.width - safeInsets.left - safeInsets.right, 460)
      let height = min(bounds.height - safeInsets.top - safeInsets.bottom, max(180, measuredContentHeight()))
      let frame = CGRect(x: (bounds.width - width) / 2, y: (bounds.height - height) / 2, width: width, height: height)
      return .init(frame: frame, sourceRect: nil, resolvedDirection: .down)
    }

    let direction: FKAnchor.Direction = {
      switch anchor.direction {
      case .up, .down:
        return anchor.direction
      case .auto:
        let upSpace = max(0, sourceRect.minY - (safeInsets.top + 8))
        let downSpace = max(0, (bounds.height - safeInsets.bottom - 8) - sourceRect.maxY)
        return downSpace >= upSpace ? .down : .up
      }
    }()

    let attachmentY: CGFloat = (anchor.edge == .top) ? sourceRect.minY : sourceRect.maxY
    let availableHeight: CGFloat = {
      switch direction {
      case .down:
        return max(0, (bounds.height - safeInsets.bottom - 8) - (attachmentY + anchor.offset))
      case .up:
        return max(0, (attachmentY - anchor.offset) - (safeInsets.top + 8))
      case .auto:
        return 0
      }
    }()

    let measured = measuredContentHeight()
    let height = min(availableHeight, max(180, measured))

    let width: CGFloat = {
      switch anchor.widthPolicy {
      case .matchAnchor:
        return sourceRect.width
      case .matchContainer:
        return bounds.width - safeInsets.left - safeInsets.right
      case let .fixed(value):
        return min(bounds.width - safeInsets.left - safeInsets.right, max(0, value))
      }
    }()

    let x: CGFloat = {
      let raw: CGFloat
      switch anchor.alignment {
      case .leading:
        raw = sourceRect.minX
      case .center:
        raw = sourceRect.midX - width / 2
      case .trailing:
        raw = sourceRect.maxX - width
      case .fill:
        raw = safeInsets.left
      }
      let minX = safeInsets.left
      let maxX = bounds.width - safeInsets.right - width
      return min(max(raw, minX), maxX)
    }()

    let y: CGFloat = {
      switch direction {
      case .down:
        // Edge-attached rule: panel starts exactly from the anchor edge + configured offset.
        return attachmentY + anchor.offset
      case .up:
        return attachmentY - anchor.offset - height
      case .auto:
        return attachmentY + anchor.offset
      }
    }()

    return .init(frame: CGRect(x: x, y: y, width: width, height: height), sourceRect: sourceRect, resolvedDirection: direction)
  }
}
