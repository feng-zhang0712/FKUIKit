import UIKit

/// Internal view controller used by `FKAnchorHost`.
///
/// Responsibilities:
/// - Hosts the anchor presentation root view (mask/backdrop + chrome + content container)
/// - Installs gestures (tap to dismiss, pan to dismiss)
/// - Exposes a single layout update entry point
@MainActor
final class FKAnchorHostViewController: UIViewController {
  struct MaskStyle {
    var alpha: CGFloat
  }

  struct Layout {
    var hostBounds: CGRect
    var presentationFrame: CGRect
    var maskCoverageRect: CGRect
    var anchorLineY: CGFloat
    var direction: FKAnchor.Direction
  }

  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?

  private let configuration: FKPresentationConfiguration

  let contentContainerView = UIView()
  let chromeView = UIView()
  /// Outer container that carries shadow (must not clip).
  private let shadowContainerView = UIView()
  /// Inner card that clips content to rounded corners.
  private let cardView = UIView()
  /// Public handle for layout/animation; maps to `shadowContainerView`.
  let wrapperView = UIView()

  private let maskView = FKAnchorMaskView()
  private lazy var tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(handleTapMask(_:)))
  private lazy var panToDismiss = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

  private var panStartFrame: CGRect = .zero
  private var currentLayout: Layout?

  private var rootView: FKAnchorRootView {
    view as! FKAnchorRootView
  }

  init(configuration: FKPresentationConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func loadView() {
    view = FKAnchorRootView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    // Mask/backdrop
    maskView.backgroundColor = maskColor()
    maskView.alpha = 0
    view.addSubview(maskView)

    // Wrapper/chrome/content
    // Keep a clear hierarchy:
    // - `shadowContainerView` draws shadow (must not clip)
    // - `cardView` clips and rounds corners (must clip)
    // This matches the classic “attached dropdown” feel and avoids card-like full shadows.
    shadowContainerView.backgroundColor = .clear
    shadowContainerView.layer.shadowColor = configuration.shadow.color.cgColor
    shadowContainerView.layer.shadowOpacity = configuration.shadow.opacity
    shadowContainerView.layer.shadowRadius = configuration.shadow.radius
    shadowContainerView.layer.shadowOffset = configuration.shadow.offset
    shadowContainerView.layer.masksToBounds = false

    cardView.backgroundColor = .systemBackground
    cardView.layer.cornerRadius = configuration.cornerRadius
    cardView.layer.masksToBounds = true

    if configuration.border.isEnabled {
      cardView.layer.borderColor = configuration.border.color.cgColor
      cardView.layer.borderWidth = configuration.border.width
    }

    contentContainerView.backgroundColor = .clear
    chromeView.backgroundColor = .clear
    chromeView.isUserInteractionEnabled = false

    cardView.addSubview(contentContainerView)
    cardView.addSubview(chromeView)
    shadowContainerView.addSubview(cardView)

    // `wrapperView` is a stable alias used by the host; keep it as the shadow container.
    wrapperView.addSubview(shadowContainerView)
    view.addSubview(wrapperView)

    // Gestures
    if configuration.dismissBehavior.allowsTapOutside {
      maskView.isUserInteractionEnabled = true
      maskView.addGestureRecognizer(tapToDismiss)
    } else {
      maskView.isUserInteractionEnabled = false
    }

    if configuration.dismissBehavior.allowsSwipe {
      panToDismiss.maximumNumberOfTouches = 1
      wrapperView.addGestureRecognizer(panToDismiss)
    }
  }

  var currentPresentationFrame: CGRect { wrapperView.frame }

  func applyLayout(_ layout: Layout) {
    currentLayout = layout
    maskView.frame = layout.hostBounds
    maskView.coverageRect = layout.maskCoverageRect

    wrapperView.frame = layout.presentationFrame
    shadowContainerView.frame = wrapperView.bounds
    cardView.frame = shadowContainerView.bounds
    chromeView.frame = cardView.bounds
    contentContainerView.frame = cardView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))

    // Corner strategy: keep the attached edge “straight” to avoid a modal-card feel.
    switch layout.direction {
    case .down:
      cardView.layer.maskedCorners = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    case .up:
      cardView.layer.maskedCorners = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
      ]
    case .auto:
      cardView.layer.maskedCorners = [
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    }

    // Shadow strategy: follow the free edge (bottom for below, top for above).
    updateShadowPath(for: layout.direction)

    // Keep host view transparent to touches outside interactive zones.
    rootView.interactiveRect = layout.maskCoverageRect.union(layout.presentationFrame)
  }

  func animateMaskAlpha(_ alpha: CGFloat) {
    maskView.alpha = alpha
  }

  private func maskColor() -> UIColor {
    // Keep anchor mask aligned with the configured backdrop dim when possible.
    switch configuration.backdropStyle {
    case let .dim(color, alpha):
      return color.withAlphaComponent(alpha)
    default:
      return UIColor.black.withAlphaComponent(0.35)
    }
  }

  private func updateShadowPath(for direction: FKAnchor.Direction) {
    let shouldShowShadow = configuration.shadow.opacity > 0 && configuration.shadow.radius > 0
    if !shouldShowShadow {
      shadowContainerView.layer.shadowOpacity = 0
      shadowContainerView.layer.shadowPath = nil
      return
    }

    let b = cardView.bounds
    let radius = configuration.shadow.radius
    let stripThickness = max(2, radius * 2)
    let rect: CGRect = {
      switch direction {
      case .down:
        return CGRect(x: 0, y: b.maxY - stripThickness, width: b.width, height: stripThickness + radius * 2)
      case .up:
        return CGRect(x: 0, y: -radius * 2, width: b.width, height: stripThickness + radius * 2)
      case .auto:
        return CGRect(x: 0, y: b.maxY - stripThickness, width: b.width, height: stripThickness + radius * 2)
      }
    }()
    shadowContainerView.layer.shadowPath = UIBezierPath(rect: rect).cgPath
  }

  @objc private func handleTapMask(_ recognizer: UITapGestureRecognizer) {
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    onRequestDismiss?()
  }

  @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.dismissBehavior.allowsSwipe else { return }
    guard let currentLayout else { return }
    let translation = recognizer.translation(in: view)

    switch recognizer.state {
    case .began:
      panStartFrame = wrapperView.frame
    case .changed:
      let signedDismissDrag: CGFloat = {
        // When expanding down from anchor, dismiss by dragging up (towards the anchor line).
        // When expanding up, dismiss by dragging down.
        switch currentLayout.direction {
        case .down: return -translation.y
        case .up: return translation.y
        case .auto: return -translation.y
        }
      }()

      let startHeight = max(1, panStartFrame.height)
      // Use real frame/height updates (instead of transform-only translation) so clipping, corners,
      // shadow path, and content insets stay physically correct during interactive drag.
      let newHeight = max(0, min(startHeight, startHeight - signedDismissDrag))

      let newFrame = frame(forHeight: newHeight, basedOn: panStartFrame, anchorLineY: currentLayout.anchorLineY, direction: currentLayout.direction)
      wrapperView.frame = newFrame
      shadowContainerView.frame = wrapperView.bounds
      cardView.frame = shadowContainerView.bounds
      chromeView.frame = cardView.bounds
      contentContainerView.frame = cardView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))
      updateShadowPath(for: currentLayout.direction)

      let progress = min(max(1 - (newHeight / startHeight), 0), 1)
      onProgress?(progress)
      maskView.alpha = max(0, 1 - progress)
    case .ended, .cancelled:
      let velocity = recognizer.velocity(in: view).y
      let startHeight = max(1, panStartFrame.height)
      let currentHeight = max(0, wrapperView.frame.height)
      let progress = min(max(1 - (currentHeight / startHeight), 0), 1)

      let shouldDismiss: Bool = {
        if progress > 0.35 { return true }
        let dismissVelocity: CGFloat = {
          switch currentLayout.direction {
          case .down: return -velocity
          case .up: return velocity
          case .auto: return -velocity
          }
        }()
        return dismissVelocity > 900
      }()
      if shouldDismiss {
        onRequestDismiss?()
      } else {
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
          self.wrapperView.frame = self.panStartFrame
          self.shadowContainerView.frame = self.wrapperView.bounds
          self.cardView.frame = self.shadowContainerView.bounds
          self.chromeView.frame = self.cardView.bounds
          self.contentContainerView.frame = self.cardView.bounds.inset(by: UIEdgeInsets(self.configuration.contentInsets))
          self.updateShadowPath(for: currentLayout.direction)
          self.maskView.alpha = 1
        } completion: { _ in
          self.onProgress?(0)
        }
      }
    default:
      break
    }
  }

  private func frame(
    forHeight height: CGFloat,
    basedOn baseFrame: CGRect,
    anchorLineY: CGFloat,
    direction: FKAnchor.Direction
  ) -> CGRect {
    var frame = baseFrame
    frame.size.height = height
    switch direction {
    case .down:
      frame.origin.y = anchorLineY
    case .up:
      frame.origin.y = anchorLineY - height
    case .auto:
      frame.origin.y = anchorLineY
    }
    return frame
  }
}

private final class FKAnchorMaskView: UIView {
  var coverageRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    coverageRect.contains(point)
  }
}

private final class FKAnchorRootView: UIView {
  var interactiveRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    interactiveRect.contains(point)
  }
}

