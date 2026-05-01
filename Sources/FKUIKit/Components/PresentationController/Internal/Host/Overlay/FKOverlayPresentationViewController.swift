import UIKit

/// Overlay-based presentation container that supports passthrough outside the popup.
@MainActor
final class FKOverlayPresentationViewController: UIViewController, UIGestureRecognizerDelegate {
  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?

  private let configuration: FKPresentationConfiguration

  private let rootView = FKOverlayRootView()
  private let backdropView = FKPresentationBackdropView()
  private let wrapperView = UIView()
  private let contentContainerView = UIView()
  private let chromeView = UIView()

  private lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  private lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  private weak var hostedContentView: UIView?

  private var resolvedDetentHeights: [CGFloat] = []
  private var currentDetentIndex: Int = 0
  private var panStartFrame: CGRect = .zero
  private var isPanningSheet: Bool = false

  init(configuration: FKPresentationConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func loadView() {
    view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    backdropView.frame = view.bounds
    backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backdropView.configure(with: configuration.backdropStyle)
    view.addSubview(backdropView)

    wrapperView.backgroundColor = .systemBackground
    wrapperView.addSubview(contentContainerView)
    wrapperView.addSubview(chromeView)

    contentContainerView.backgroundColor = .clear
    chromeView.backgroundColor = .clear
    chromeView.isUserInteractionEnabled = false

    view.addSubview(wrapperView)

    installGestures()
    recalculateDetentsIfNeeded()
    currentDetentIndex = configuration.sheet.initialDetentIndex
  }

  func embedContent(_ contentController: UIViewController) {
    addChild(contentController)
    contentController.view.translatesAutoresizingMaskIntoConstraints = false
    contentContainerView.addSubview(contentController.view)
    NSLayoutConstraint.activate([
      contentController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
      contentController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
      contentController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
      contentController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
    ])
    contentController.didMove(toParent: self)
    hostedContentView = contentController.view
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    let apply = {
      self.backdropView.configure(with: self.configuration.backdropStyle)
      self.wrapperView.frame = self.frameOfWrapper()
      self.layoutContent()
      self.applyAppearance()
      self.updatePassthroughHitTesting()
    }
    if animated {
      UIView.animate(withDuration: max(0, duration), delay: 0, options: [options, .beginFromCurrentState, .allowUserInteraction], animations: apply)
    } else {
      apply()
    }
  }

  func animatePresentation(isPresentation: Bool, animated: Bool, completion: @escaping () -> Void) {
    if isPresentation {
      // Normalize frame before presenting animation.
      updateLayout(animated: false, duration: 0, options: .curveLinear)
    } else {
      // For dismissal, animate from the current on-screen interactive state to avoid snap/flash.
      updatePassthroughHitTesting()
    }

    let duration: TimeInterval = animated ? 0.28 : 0
    if duration == 0 {
      backdropView.alpha = isPresentation ? 1 : 0
      wrapperView.alpha = isPresentation ? 1 : 0
      wrapperView.transform = .identity
      completion()
      return
    }

    if isPresentation {
      wrapperView.alpha = 0
      wrapperView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
      backdropView.alpha = 0
    }

    UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
      self.backdropView.alpha = isPresentation ? 1 : 0
      self.wrapperView.alpha = isPresentation ? 1 : 0
      self.wrapperView.transform = isPresentation ? .identity : CGAffineTransform(scaleX: 0.98, y: 0.98)
    } completion: { _ in
      completion()
    }
  }

  // MARK: - Gestures

  private func installGestures() {
    // Backdrop tap-to-dismiss only when NOT in passthrough background interaction mode.
    if !configuration.backgroundInteraction.isEnabled,
       configuration.dismissBehavior.allowsTapOutside,
       configuration.dismissBehavior.allowsBackdropTap {
      backdropView.isUserInteractionEnabled = true
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.isUserInteractionEnabled = false
      backdropView.removeGestureRecognizer(tapToDismissGesture)
    }

    let allowsSwipe: Bool = {
      if case .center(_) = configuration.layout { return configuration.center.dismissEnabled }
      return configuration.dismissBehavior.allowsSwipe
    }()
    if allowsSwipe {
      panToDismissGesture.maximumNumberOfTouches = 1
      panToDismissGesture.delegate = self
      panToDismissGesture.cancelsTouchesInView = false
      wrapperView.addGestureRecognizer(panToDismissGesture)
    }
  }

  @objc private func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    onRequestDismiss?()
  }

  @objc private func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      handleSheetPan(recognizer)
    case .center(_):
      handleCenterPan(recognizer)
    default:
      break
    }
  }

  private func handleCenterPan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.center.dismissEnabled else { return }
    let translation = recognizer.translation(in: view)
    let progress = min(max(abs(translation.y) / max(1, view.bounds.height * 0.4), 0), 1)
    onProgress?(progress)
    let velocityY = abs(recognizer.velocity(in: view).y)
    if recognizer.state == .ended || recognizer.state == .cancelled {
      if progress > configuration.center.dismissProgressThreshold || velocityY > configuration.center.dismissVelocityThreshold {
        onRequestDismiss?()
      } else {
        onProgress?(0)
      }
    }
  }

  private func handleSheetPan(_ recognizer: UIPanGestureRecognizer) {
    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: view)
    let velocity = recognizer.velocity(in: view)

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      panStartFrame = wrapperView.frame
    case .changed:
      guard isPanningSheet else { return }
      let frame = interactiveSheetFrame(translationY: translation.y)
      wrapperView.frame = frame
      layoutContent()
      applyAppearance()
      onProgress?(sheetDismissProgress())
      updatePassthroughHitTesting()
    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false
      let shouldDismiss = sheetShouldDismiss(translationY: translation.y, velocityY: velocity.y)
      if shouldDismiss {
        onProgress?(1)
        onRequestDismiss?()
        return
      }
      // Snap to nearest detent.
      let target = nearestDetentIndex(velocityY: velocity.y)
      currentDetentIndex = target
      UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
        self.wrapperView.frame = self.frameOfWrapper()
        self.layoutContent()
        self.applyAppearance()
        self.updatePassthroughHitTesting()
      } completion: { _ in
        self.onProgress?(0)
      }
    default:
      break
    }
  }

  // MARK: - Layout helpers

  private func frameOfWrapper() -> CGRect {
    let bounds = view.bounds
    let safeInsets = containerSafeInsets()

    switch configuration.layout {
    case .bottomSheet(_):
      let height = resolvedSheetHeight(bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(bounds: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y = bounds.height - height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0)
      return CGRect(x: x, y: y, width: width, height: height)
    case .topSheet(_):
      let height = resolvedSheetHeight(bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(bounds: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y: CGFloat = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      return CGRect(x: x, y: y, width: width, height: height)
    case .center(_):
      return resolvedCenterFrame(bounds: bounds, safeInsets: safeInsets)
    case .anchor:
      return resolvedCenterFrame(bounds: bounds, safeInsets: safeInsets)
    case let .edge(edge):
      return edgeFrame(bounds: bounds, edge: edge)
    }
  }

  private func layoutContent() {
    contentContainerView.frame = wrapperView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))
    chromeView.frame = wrapperView.bounds
    hostedContentView?.frame = contentContainerView.bounds
  }

  private func applyAppearance() {
    wrapperView.layer.cornerRadius = configuration.cornerRadius
    wrapperView.layer.masksToBounds = true
    wrapperView.layer.shadowColor = configuration.shadow.color.cgColor
    wrapperView.layer.shadowOpacity = configuration.shadow.opacity
    wrapperView.layer.shadowRadius = configuration.shadow.radius
    wrapperView.layer.shadowOffset = configuration.shadow.offset
    wrapperView.layer.shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: configuration.cornerRadius).cgPath
    if configuration.border.isEnabled {
      wrapperView.layer.borderColor = configuration.border.color.cgColor
      wrapperView.layer.borderWidth = configuration.border.width
    } else {
      wrapperView.layer.borderWidth = 0
    }
  }

  private func updatePassthroughHitTesting() {
    // In overlay host, passthrough means: only popup area intercepts.
    rootView.interactiveRect = wrapperView.frame
  }

  private func containerSafeInsets() -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea:
      return .zero
    case .containerRespectsSafeArea:
      return view.safeAreaInsets
    }
  }

  // MARK: - Sheet sizing

  private func recalculateDetentsIfNeeded() {
    let bounds = view.bounds
    let availableHeight = bounds.height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? (view.safeAreaInsets.top + view.safeAreaInsets.bottom) : 0)
    resolvedDetentHeights = configuration.sheet.detents.map { detent in
      resolve(detent: detent, availableHeight: availableHeight)
    }
    currentDetentIndex = max(0, min(currentDetentIndex, max(0, resolvedDetentHeights.count - 1)))
  }

  private func resolve(detent: FKPresentationDetent, availableHeight: CGFloat) -> CGFloat {
    let value: CGFloat
    switch detent {
    case .fitContent:
      let maxHeight = availableHeight * configuration.sheet.maximumFitContentHeightFraction
      let preferred = contentPreferredHeight()
      value = min(maxHeight, preferred)
    case let .fixed(points):
      value = min(availableHeight, max(0, points))
    case let .fraction(fraction):
      value = min(availableHeight, max(0, fraction) * availableHeight)
    case .full:
      value = availableHeight
    }
    return value
  }

  private func contentPreferredHeight() -> CGFloat {
    let preferred = children.first?.preferredContentSize.height ?? 0
    if preferred > 0 { return preferred }
    return 320
  }

  private func resolvedSheetHeight(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    recalculateDetentsIfNeeded()
    if resolvedDetentHeights.indices.contains(currentDetentIndex) {
      return resolvedDetentHeights[currentDetentIndex]
    }
    return min(bounds.height * 0.5, 320)
  }

  private func resolvedSheetWidth(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    let availableWidth = bounds.width - safeInsets.left - safeInsets.right
    switch configuration.sheet.widthPolicy {
    case .fill:
      return bounds.width
    case let .fraction(value):
      return min(availableWidth, max(220, availableWidth * min(max(value, 0.2), 1)))
    case let .max(value):
      return min(availableWidth, max(220, value))
    }
  }

  // MARK: - Center sizing

  private func resolvedCenterFrame(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGRect {
    let margins = configuration.center.minimumMargins
    let maxWidth = bounds.width - (CGFloat(margins.leading + margins.trailing) + safeInsets.left + safeInsets.right)
    let maxHeight = bounds.height - (CGFloat(margins.top + margins.bottom) + safeInsets.top + safeInsets.bottom)

    let size: CGSize
    switch configuration.center.size {
    case let .fixed(fixed):
      size = .init(width: min(maxWidth, max(0, fixed.width)), height: min(maxHeight, max(0, fixed.height)))
    case let .fitted(maxSize):
      let contentW = max(220, children.first?.preferredContentSize.width ?? 0)
      let contentH = max(220, contentPreferredHeight())
      size = .init(
        width: min(maxWidth, min(maxSize.width, contentW)),
        height: min(maxHeight, min(maxSize.height, contentH))
      )
    }
    let originX = (bounds.width - size.width) / 2
    let originY = (bounds.height - size.height) / 2
    return CGRect(x: originX, y: originY, width: size.width, height: size.height)
  }

  private func edgeFrame(bounds: CGRect, edge: UIRectEdge) -> CGRect {
    let width = min(bounds.width * 0.85, 420)
    let height = min(bounds.height * 0.85, 640)
    if edge.contains(.left) {
      return CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.right) {
      return CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.top) {
      return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
  }

  // MARK: - Sheet interaction helpers

  private func interactiveSheetFrame(translationY: CGFloat) -> CGRect {
    var frame = panStartFrame
    let bounds = view.bounds
    let safeInsets = containerSafeInsets()
    let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    let bottomY = bounds.height - bottomExtra

    let minHeight = resolvedDetentHeights.min() ?? 240
    let maxHeight = resolvedDetentHeights.max() ?? bounds.height * 0.9

    switch configuration.layout {
    case .bottomSheet(_):
      if currentDetentIndex == 0, translationY > 0 {
        frame.origin.y = panStartFrame.origin.y + translationY
      } else {
        frame.size.height = panStartFrame.height - translationY
        frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
        frame.origin.y = bottomY - frame.size.height
      }
    case .topSheet(_):
      let minY = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      if currentDetentIndex == 0, translationY < 0 {
        frame.origin.y = panStartFrame.origin.y + translationY
      } else {
        frame.size.height = panStartFrame.height + translationY
        frame.size.height = min(max(frame.size.height, minHeight - configuration.sheet.dismissThreshold), maxHeight + configuration.sheet.dismissThreshold)
        frame.origin.y = minY
      }
    default:
      break
    }
    return frame
  }

  private func sheetDismissProgress() -> CGFloat {
    let bounds = view.bounds
    switch configuration.layout {
    case .topSheet(_):
      let safeInsets = containerSafeInsets()
      let minY = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.top : 0
      let progress = (minY - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    default:
      let safeInsets = containerSafeInsets()
      let minHeight = resolvedDetentHeights.min() ?? 240
      let extra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
      let maxY = bounds.height - minHeight - extra
      let progress = (maxY - wrapperView.frame.minY) / max(1, bounds.height * 0.25)
      return min(max(progress, 0), 1)
    }
  }

  private func sheetShouldDismiss(translationY: CGFloat, velocityY: CGFloat) -> Bool {
    guard configuration.dismissBehavior.allowsSwipe else { return false }
    switch configuration.layout {
    case .bottomSheet(_):
      guard currentDetentIndex == 0 else { return false }
      return translationY > configuration.sheet.dismissThreshold || velocityY > configuration.sheet.dismissVelocityThreshold
    case .topSheet(_):
      guard currentDetentIndex == 0 else { return false }
      return translationY < -configuration.sheet.dismissThreshold || velocityY < -configuration.sheet.dismissVelocityThreshold
    default:
      return false
    }
  }

  private func nearestDetentIndex(velocityY: CGFloat) -> Int {
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
    // Nearest by height.
    let bounds = view.bounds
    let safeInsets = containerSafeInsets()
    let bottomExtra = configuration.safeAreaPolicy == .containerRespectsSafeArea ? safeInsets.bottom : 0
    let currentHeight: CGFloat = {
      switch configuration.layout {
      case .bottomSheet(_):
        return bounds.height - wrapperView.frame.minY - bottomExtra
      default:
        return wrapperView.frame.height
      }
    }()
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

  // MARK: UIGestureRecognizerDelegate

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: view)
    return abs(velocity.y) >= abs(velocity.x)
  }
}

private final class FKOverlayRootView: UIView {
  var interactiveRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    // Only the popup should intercept touches; the rest must passthrough.
    interactiveRect.contains(point)
  }
}

