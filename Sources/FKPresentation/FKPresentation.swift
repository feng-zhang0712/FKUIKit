//
// FKPresentation.swift
//
// Anchored overlay/panel (not `UIPresentationController`): mask, animation, safe-area handling,
// and repositioning are driven by configuration.
//

import UIKit
import FKUIKitCore

@MainActor
public protocol FKPresentationDataSource: AnyObject {
  /// Optional preferred size. When `nil`, the size is computed from intrinsic/fitting/safe-area.
  func presentationPreferredSize(_ presentation: FKPresentation) -> CGSize?
  /// Content root view provided by the data source.
  /// When `show(..., content:)` already supplies a `UIView`/`UIViewController`, this is not called.
  func presentationContentView(_ presentation: FKPresentation) -> UIView?
}

public extension FKPresentationDataSource {
  func presentationPreferredSize(_ presentation: FKPresentation) -> CGSize? { nil }
  func presentationContentView(_ presentation: FKPresentation) -> UIView? { nil }
}

/// Presentation lifecycle, dismissal gating, and repositioning hooks.
@MainActor
public protocol FKPresentationDelegate: AnyObject {
  /// Called after the panel is added to the hierarchy and before (or right after) `frame` is finalized.
  /// The exact timing depends on the current implementation.
  func presentationWillPresent(_ presentation: FKPresentation)
  func presentationDidPresent(_ presentation: FKPresentation)

  func presentationShouldDismiss(_ presentation: FKPresentation) -> Bool
  func presentationWillDismiss(_ presentation: FKPresentation)
  func presentationDidDismiss(_ presentation: FKPresentation)

  /// Before repositioning, you may rewrite `sourceRect` and `sourceView` (in-out).
  func presentation(_ presentation: FKPresentation, willRepositionTo rect: inout CGRect, in view: inout UIView)
}

public extension FKPresentationDelegate {
  func presentationWillPresent(_ presentation: FKPresentation) {}
  func presentationDidPresent(_ presentation: FKPresentation) {}
  func presentationShouldDismiss(_ presentation: FKPresentation) -> Bool { true }
  func presentationWillDismiss(_ presentation: FKPresentation) {}
  func presentationDidDismiss(_ presentation: FKPresentation) {}
  func presentation(_ presentation: FKPresentation, willRepositionTo rect: inout CGRect, in view: inout UIView) {}
}

/// Coordinates mask, content container, and animations.
/// `show` / `dismiss` are the only public state transitions.
@MainActor
public final class FKPresentation {
  // MARK: Public API
  public weak var delegate: FKPresentationDelegate?
  public weak var dataSource: FKPresentationDataSource?

  /// Changes during presentation typically trigger re-layout and appearance updates (implementation-dependent).
  public var configuration: Configuration = .default

  /// Whether the panel is currently presented (includes animation in-flight; driven by internal state).
  public private(set) var isPresented: Bool = false

  // MARK: Content holders
  private enum Content {
    case uiView(UIView)
    case uiViewController(UIViewController)
  }

  private var content: Content?

  // MARK: Anchor
  private weak var sourceView: UIView?
  private var sourceRect: CGRect = .zero
  /// Resolved vertical anchor direction (above/below) derived from `configuration.layout`
  /// (e.g. `preferBelowSource`, `allowFlipToAbove`) and available space.
  /// Affects: the panel Y position, available height, show/dismiss transforms,
  /// and which edge the shadow follows when `ShadowEdgeStyle.followsPresentation` is enabled.
  private var preferredAnchorVertical: AnchorVertical = .below

  /// Vertical placement relative to the source rect: below or above.
  private enum AnchorVertical {
    /// Panel is placed below the source (typical dropdown behavior).
    case below
    /// Panel is placed above the source (flipped when there isn't enough room).
    case above
  }

  // MARK: Hosting / overlay
  private weak var hostContainer: UIView?
  private var directHostChild: UIView?

  private var maskView: UIView?
  private var presentationContainerView: UIView?
  private var contentChromeView: UIView?

  private var embeddedContentView: UIView?
  private weak var embeddedContentViewController: UIViewController?

  private var tapDismissRecognizer: UITapGestureRecognizer?

  // MARK: Internal flags
  private var isRepositioning: Bool = false

  public init() {}

  // MARK: Show

  /// Present `content` anchored to `sourceView` inside `container` (auto-resolved when nil).
  public func show(
    from sourceView: UIView,
    sourceRect: CGRect? = nil,
    content: UIView,
    in container: UIView? = nil,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    self.content = .uiView(content)
    showInternal(
      from: sourceView,
      sourceRect: sourceRect ?? sourceView.bounds,
      in: container,
      animated: animated,
      completion: completion
    )
  }

  /// Present a `UIViewController` as embedded content (internal handling includes `addChild`, etc.).
  public func show(
    from sourceView: UIView,
    sourceRect: CGRect? = nil,
    content: UIViewController,
    in container: UIView? = nil,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    self.content = .uiViewController(content)
    showInternal(
      from: sourceView,
      sourceRect: sourceRect ?? sourceView.bounds,
      in: container,
      animated: animated,
      completion: completion
    )
  }

  private func showInternal(
    from sourceView: UIView,
    sourceRect: CGRect,
    in container: UIView?,
    animated: Bool,
    completion: (() -> Void)?
  ) {
    // If already visible, dismiss first for simplicity.
    if isPresented { dismiss(animated: false, completion: nil) }

    self.sourceView = sourceView
    self.sourceRect = sourceRect

    let host = container ?? findHostContainer(for: sourceView)
    self.hostContainer = host
    self.directHostChild = findDirectChild(of: host, containing: sourceView)

    buildPresentationIfNeeded(in: host)
    // Keep the source view visually above the presentation.
    // This makes the presentation look "embedded" into the anchor bottom edge.
    bringSourceViewAbovePresentation()
    // Content is embedded via `prepareForLayout` → `applyAppearance` → `ensureContentInsetWrapper` → `embedContent`
    // to avoid duplicate chrome embedding.
    prepareForLayout()

    // Compute & apply final frame BEFORE animation (height already decided).
    let (presentationFrame, _) = computeAndApplyFrames()
    presentationContainerView?.frame = presentationFrame

    // Reduce Motion: avoid transform-based motion entirely.
    let reduced = UIAccessibility.isReduceMotionEnabled
    if reduced {
      presentationContainerView?.transform = .identity
    } else {
      presentationContainerView?.transform = transformForPhase(.show, anchorVertical: preferredAnchorVertical)
    }

    // Apply initial mask state.
    applyMaskInitial()

    delegate?.presentationWillPresent(self)
    isPresented = true

    // Reduce Motion handling.
    let showAnim = reduced ? reduceShowPhase() : configuration.animation.show
    let showDuration = showAnim.duration

    let allowInteraction = configuration.interaction.isUserInteractionEnabledDuringAnimation
    if !allowInteraction {
      presentationContainerView?.isUserInteractionEnabled = false
      maskView?.isUserInteractionEnabled = false
    }
    
    if animated && showDuration > 0 {
      animateShow(duration: showDuration, phase: showAnim) { [weak self] in
        guard let self else { return }
        if !allowInteraction {
          self.presentationContainerView?.isUserInteractionEnabled = true
          self.maskView?.isUserInteractionEnabled = true
        }
        self.delegate?.presentationDidPresent(self)
        completion?()
      }
    } else {
      // Immediately set to identity/visible.
      presentationContainerView?.transform = .identity
      maskView?.alpha = configuration.mask.enabled ? configuration.mask.alpha : 0
      delegate?.presentationDidPresent(self)
      completion?()
    }

    observeRepositionIfNeeded()
  }

  // MARK: Dismiss

  /// Remove the mask and content. If not presented, call `completion` immediately.
  public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
    guard isPresented else { completion?(); return }

    delegate?.presentationWillDismiss(self)
    isPresented = false
    removeRepositionObservers()

    let reduced = UIAccessibility.isReduceMotionEnabled
    let dismissAnim = reduced ? reduceDismissPhase() : configuration.animation.dismiss
    let allowInteraction = configuration.interaction.isUserInteractionEnabledDuringAnimation
    if !allowInteraction {
      presentationContainerView?.isUserInteractionEnabled = false
      maskView?.isUserInteractionEnabled = false
    }

    let finish = { [weak self] in
      guard let self else { return }
      self.cleanupOverlay()
      self.delegate?.presentationDidDismiss(self)
      completion?()
    }

    if animated, dismissAnim.duration > 0 {
      UIView.animate(withDuration: dismissAnim.duration, delay: dismissAnim.delay, options: [.curveEaseOut, .beginFromCurrentState]) {
        self.maskView?.alpha = 0
        if reduced {
          self.presentationContainerView?.transform = .identity
        } else {
          self.presentationContainerView?.transform = self.transformForPhase(.dismiss, anchorVertical: self.preferredAnchorVertical)
        }
        self.contentChromeView?.alpha = 0
      } completion: { _ in
        finish()
      }
    } else {
      finish()
    }
  }

  // MARK: Config updates

  public func updateConfiguration(
    _ configuration: Configuration,
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    self.configuration = configuration
    applyAppearance()
    guard isPresented else { completion?(); return }
    recalculateAndReposition(animated: animated, completion: completion)
  }

  public func recalculateAndReposition(
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    guard isPresented else { completion?(); return }
    guard let host = hostContainer else { completion?(); return }
    isRepositioning = true
    defer { isRepositioning = false }

    // Ask delegate to adjust anchor before recomputing.
    if var view = sourceView {
      var rect = sourceRect
      delegate?.presentation(self, willRepositionTo: &rect, in: &view)
      sourceRect = rect
      self.sourceView = view
      directHostChild = findDirectChild(of: host, containing: view)
    }

    // Recompute final frame & apply (do not animate height changes).
    let (presentationFrame, chromeFrame) = computeAndApplyFrames()
    presentationContainerView?.frame = presentationFrame
    contentChromeView?.frame = chromeFrame
    applyMaskInitial()

    if animated, configuration.reposition.animationDuration > 0 {
      // Only animate subtle translation; final frame already applied.
      let duration = configuration.reposition.animationDuration
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
        self.presentationContainerView?.transform = .identity
      } completion: { _ in completion?() }
    } else {
      completion?()
    }
  }

  // MARK: Overlay building

  private func buildPresentationIfNeeded(in host: UIView) {
    if maskView != nil, presentationContainerView != nil, contentChromeView != nil { return }

    let mask = UIView()
    mask.translatesAutoresizingMaskIntoConstraints = false
    mask.backgroundColor = configuration.mask.backgroundColor.withAlphaComponent(configuration.mask.alpha)
    mask.alpha = configuration.mask.enabled ? 0 : 0
    mask.isUserInteractionEnabled = configuration.mask.tapToDismissEnabled

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleMaskTap(_:)))
    mask.addGestureRecognizer(tap)
    tapDismissRecognizer = tap

    let presentation = UIView()
    presentation.backgroundColor = .clear

    let chrome = UIView()
    chrome.translatesAutoresizingMaskIntoConstraints = false
    chrome.backgroundColor = configuration.appearance.backgroundColor
    chrome.alpha = configuration.appearance.alpha
    presentation.addSubview(chrome)

    NSLayoutConstraint.activate([
      chrome.topAnchor.constraint(equalTo: presentation.topAnchor),
      chrome.bottomAnchor.constraint(equalTo: presentation.bottomAnchor),
      chrome.leadingAnchor.constraint(equalTo: presentation.leadingAnchor),
      chrome.trailingAnchor.constraint(equalTo: presentation.trailingAnchor)
    ])

    // Layering rule:
    // - presentation is always above other host subviews
    // - mask is below presentation (still restricted to "below sourceView")
    // This avoids the presentation being covered by the sourceView's container.
    host.addSubview(presentation)
    host.insertSubview(mask, belowSubview: presentation)

    maskView = mask
    presentationContainerView = presentation
    contentChromeView = chrome
  }

  private func bringSourceViewAbovePresentation() {
    guard let host = hostContainer else { return }
    guard let anchorContainer = directHostChild ?? sourceView else { return }
    if anchorContainer.superview === host {
      host.bringSubviewToFront(anchorContainer)
    } else if let directChild = directHostChild, directChild.superview === host {
      host.bringSubviewToFront(directChild)
    }
  }

  // MARK: Layout & sizing

  private func prepareForLayout() {
    applyAppearance()
  }

  private func computeAndApplyFrames() -> (CGRect, CGRect) {
    guard let host = hostContainer,
          let source = sourceView,
          let presentationContainerView,
          let chrome = contentChromeView
    else {
      updateChromeShadowPath()
      return (.zero, .zero)
    }

    // Decide anchor vertical direction (below/above).
    preferredAnchorVertical = resolveAnchorVertical()

    let sourceFrame = source.convert(source.bounds, to: host)
    let usableSafeInsets = configuration.layout.clampToSafeArea ? safeAreaInsets(in: host) : UIEdgeInsets.zero
    let usableRect = host.bounds.inset(by: usableSafeInsets)

    let width = resolvePresentationWidth(using: sourceFrame, in: host, usableRect: usableRect)

    // Determine max height.
    let maxHeightCandidate = configuration.layout.maxHeight
      ?? configuration.content.maxHeight
      ?? (preferredAnchorVertical == .below
          ? (usableRect.maxY - sourceFrame.maxY - configuration.layout.verticalSpacing)
          : (sourceFrame.minY - usableRect.minY - configuration.layout.verticalSpacing))
    let maxHeight = max(maxHeightCandidate, 0)

    let insets = configuration.content.containerInsets
    let contentInsetsH = insets.leading + insets.trailing
    let containerChromeWidth = width
    let containerChromeMaxContentWidth = max(containerChromeWidth - contentInsetsH, 0)

    // Layout user content for fitting (height already determined).
    // Ensure the inset wrapper gets the correct width before fitting.
    presentationContainerView.frame = CGRect(x: 0, y: 0, width: containerChromeWidth, height: 1)
    chrome.frame = CGRect(origin: .zero, size: presentationContainerView.frame.size)
    host.layoutIfNeeded()

    let contentSize = resolveContentSize(maxHeight: maxHeight, targetWidth: containerChromeMaxContentWidth)
    let resolvedHeight = configuration.content.preferredHeight ?? contentSize.height

    let chromeHeight = resolvedHeight + insets.top + insets.bottom
    let chromeWidth = containerChromeWidth

    let x: CGFloat = {
      if case .fullWidth = configuration.layout.widthMode {
        return host.bounds.minX
      }
      return resolveX(for: sourceFrame, width: chromeWidth)
    }()
    let y: CGFloat = {
      switch preferredAnchorVertical {
      case .below:
        return min(max(sourceFrame.maxY + configuration.layout.verticalSpacing, usableRect.minY), usableRect.maxY - chromeHeight)
      case .above:
        return min(max(sourceFrame.minY - configuration.layout.verticalSpacing - chromeHeight, usableRect.minY), usableRect.maxY - chromeHeight)
      }
    }()

    let presentationFrame = CGRect(x: x, y: y, width: chromeWidth, height: chromeHeight).integral

    // chrome frame is inset by contentInsets; currently chrome itself is full presentation size,
    // User content is constrained within chrome via `contentInsetWrapper` (see `ensureContentInsetWrapper`).
    // But we still need chrome frame because for animation we keep container frame fixed.
    let chromeFrame = CGRect(origin: .zero, size: presentationFrame.size)

    // Apply size immediately; no animation on height.
    presentationContainerView.frame = presentationFrame
    chrome.frame = chromeFrame

    updateChromeShadowPath()
    return (presentationFrame, chromeFrame)
  }

  private func resolveAnchorVertical() -> AnchorVertical {
    guard configuration.layout.allowFlipToAbove else { return .below }
    // Prefer below if there is enough room; else flip to above.
    guard let host = hostContainer, let source = sourceView else { return .below }
    let sourceFrame = source.convert(source.bounds, to: host)
    let safeInsets = configuration.layout.clampToSafeArea ? safeAreaInsets(in: host) : UIEdgeInsets.zero
    let usable = host.bounds.inset(by: safeInsets)

    let belowAvailable = usable.maxY - sourceFrame.maxY - configuration.layout.verticalSpacing
    let aboveAvailable = sourceFrame.minY - usable.minY - configuration.layout.verticalSpacing

    if configuration.layout.preferBelowSource {
      if belowAvailable >= aboveAvailable { return .below }
      return .above
    } else {
      if aboveAvailable >= belowAvailable { return .above }
      return .below
    }
  }

  private func resolvePresentationWidth(using sourceFrame: CGRect, in host: UIView, usableRect: CGRect) -> CGFloat {
    let container = max(usableRect.width, 0)

    let base: CGFloat = {
      switch configuration.layout.widthMode {
      case .matchSourceWidth:
        return sourceFrame.width
      case .custom(let w):
        return w
      case .fitWithinContainer:
        let ds = dataSource?.presentationPreferredSize(self) ?? nil
        if let dsW = ds?.width, dsW > 0 { return dsW }
        return sourceFrame.width
      case .fullWidth:
        // Intentionally use host/screen width instead of safe-area clamped width.
        return host.bounds.width
      }
    }()

    var w = base
    if let minW = configuration.layout.widthMin { w = max(w, minW) }
    if let maxW = configuration.layout.widthMax { w = min(w, maxW) }

    // Clamp into usable rect.
    if case .fullWidth = configuration.layout.widthMode {
      // For fullWidth we skip clamping to safe-area width; x will also be computed from host bounds.
    } else {
      w = min(w, container)
    }
    w = max(w, 0)
    return w
  }

  private func resolveContentSize(maxHeight: CGFloat, targetWidth: CGFloat) -> CGSize {
    // Use dataSource preferred size if available.
    if let preferred = dataSource?.presentationPreferredSize(self), preferred.width > 0, preferred.height > 0 {
      let h = configuration.content.preferredHeight ?? preferred.height
      let clampedH = min(h, maxHeight > 0 ? maxHeight : h)
      let w = targetWidth > 0 ? targetWidth : preferred.width
      return CGSize(width: w, height: max(clampedH, 0))
    }

    switch content {
    case let .uiView(view):
      // If no constraints yet, force a layout pass.
      view.layoutIfNeeded()
      let fitting = CGSize(width: targetWidth > 0 ? targetWidth : 320, height: UIView.layoutFittingCompressedSize.height)
      let size = view.systemLayoutSizeFitting(
        fitting,
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
      )
      let h = configuration.content.preferredHeight ?? size.height
      let clamped = max(0, min(h, maxHeight > 0 ? maxHeight : h))
      return CGSize(width: size.width, height: clamped)

    case let .uiViewController(vc):
      // For VC, try preferredContentSize first.
      vc.loadViewIfNeeded()
      if vc.preferredContentSize != .zero {
        let preferredH = configuration.content.preferredHeight ?? vc.preferredContentSize.height
        let h = min(max(0, preferredH), maxHeight > 0 ? maxHeight : preferredH)
        let w = targetWidth > 0 ? targetWidth : vc.preferredContentSize.width
        return CGSize(width: w, height: h)
      }
      // Fallback: use VC.view fitting.
      vc.view.layoutIfNeeded()
      let fitting = CGSize(width: targetWidth > 0 ? targetWidth : 320, height: UIView.layoutFittingCompressedSize.height)
      let size = vc.view.systemLayoutSizeFitting(
        fitting,
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
      )
      let h = configuration.content.preferredHeight ?? size.height
      let clamped = max(0, min(h, maxHeight > 0 ? maxHeight : h))
      return CGSize(width: size.width, height: clamped)
    case nil:
      return CGSize(width: targetWidth, height: 220)
    }
  }

  private func resolveX(for sourceFrame: CGRect, width: CGFloat) -> CGFloat {
    switch configuration.layout.horizontalAlignment {
    case .leading:
      return sourceFrame.minX
    case .center:
      return sourceFrame.midX - width / 2
    case .trailing:
      return sourceFrame.maxX - width
    }
  }

  private func safeAreaInsets(in host: UIView) -> UIEdgeInsets {
    guard let vc = ancestorViewController(for: host) else { return .zero }
    return vc.view.safeAreaInsets
  }

  // MARK: Mask

  private func applyMaskInitial() {
    guard let host = hostContainer,
          let source = sourceView,
          let maskView
    else { return }

    if !configuration.mask.enabled {
      maskView.isHidden = true
      maskView.alpha = 0
      return
    }

    maskView.isHidden = false
    let sourceFrame = source.convert(source.bounds, to: host)
    let hostBounds = host.bounds

    // Only cover below sourceView.
    let top = sourceFrame.maxY
    let maskRect = CGRect(
      x: hostBounds.minX,
      y: top,
      width: hostBounds.width,
      height: max(0, hostBounds.maxY - top)
    )
    maskView.frame = maskRect
    maskView.backgroundColor = configuration.mask.backgroundColor.withAlphaComponent(configuration.mask.alpha)
    maskView.alpha = 0
    maskView.isUserInteractionEnabled = configuration.mask.tapToDismissEnabled
  }

  @objc private func handleMaskTap(_ recognizer: UITapGestureRecognizer) {
    guard let maskView else { return }
    guard configuration.mask.tapToDismissEnabled else { return }

    if isRepositioning, configuration.interaction.allowDismissingDuringReposition == false { return }

    let point = recognizer.location(in: maskView)

    for v in configuration.mask.passthroughViews {
      guard v.superview != nil else { continue }
      let localPoint = v.convert(point, from: maskView)
      if v.bounds.contains(localPoint) {
        return
      }
    }

    guard delegate?.presentationShouldDismiss(self) ?? true else { return }
    dismiss(animated: true, completion: nil)
  }

  // MARK: Appearance

  private func applyAppearance() {
    guard let chrome = contentChromeView
    else { return }

    chrome.backgroundColor = configuration.appearance.backgroundColor
    chrome.alpha = configuration.appearance.alpha

    let layer = chrome.layer
    layer.cornerRadius = configuration.appearance.cornerRadius
    layer.cornerCurve = configuration.appearance.cornerCurve
    layer.maskedCorners = configuration.appearance.maskedCorners
    layer.borderWidth = configuration.appearance.borderWidth
    layer.borderColor = configuration.appearance.borderColor.cgColor

    let shouldClip: Bool
    if let clipsToBounds = configuration.appearance.clipsToBounds {
      shouldClip = clipsToBounds
    } else {
      shouldClip = (configuration.appearance.shadow == nil)
    }
    chrome.clipsToBounds = shouldClip

    if let shadow = configuration.appearance.shadow {
      layer.shadowColor = shadow.color.cgColor
      layer.shadowOpacity = shadow.opacity
      layer.shadowRadius = shadow.radius
      layer.shadowOffset = shadow.offset
      updateChromeShadowPath()
    } else {
      layer.shadowOpacity = 0
      layer.shadowColor = nil
      layer.shadowRadius = 0
      layer.shadowOffset = .zero
      layer.shadowPath = nil
    }

    // Apply `configuration.content.containerInsets` via the inset wrapper.
    ensureContentInsetWrapper()
  }

  /// Update `contentChromeView`'s `shadowPath` based on `shadow.edgeStyle` and current bounds/anchor.
  private func updateChromeShadowPath() {
    guard let chrome = contentChromeView,
          let shadow = configuration.appearance.shadow
    else {
      contentChromeView?.layer.shadowPath = nil
      return
    }

    let bounds = chrome.bounds
    guard bounds.width > 0, bounds.height > 0 else {
      chrome.layer.shadowPath = nil
      return
    }

    chrome.layer.shadowPath = Self.chromeShadowPath(
      in: bounds,
      cornerRadius: configuration.appearance.cornerRadius,
      edgeStyle: shadow.edgeStyle,
      anchorVertical: preferredAnchorVertical,
      shadowRadius: shadow.radius,
      shadowOffset: shadow.offset
    )
  }

  private static func chromeShadowPath(
    in bounds: CGRect,
    cornerRadius: CGFloat,
    edgeStyle: Configuration.ShadowEdgeStyle,
    anchorVertical: AnchorVertical,
    shadowRadius: CGFloat,
    shadowOffset: CGSize
  ) -> CGPath {
    switch edgeStyle {
    case .omnidirectional:
      let r = min(cornerRadius, min(bounds.width, bounds.height) / 2)
      return UIBezierPath(roundedRect: bounds, cornerRadius: r).cgPath

    case .followsPresentation:
      let e: UIRectEdge = (anchorVertical == .below) ? .bottom : .top
      return EdgeStripShadowPath.cgPath(
        in: bounds,
        edges: e,
        shadowRadius: shadowRadius,
        shadowOffset: shadowOffset
      )

    case .edges(let e):
      if e.isEmpty {
        let r = min(cornerRadius, min(bounds.width, bounds.height) / 2)
        return UIBezierPath(roundedRect: bounds, cornerRadius: r).cgPath
      }
      return EdgeStripShadowPath.cgPath(
        in: bounds,
        edges: e,
        shadowRadius: shadowRadius,
        shadowOffset: shadowOffset
      )
    }
  }

  private var contentInsetWrapper: UIView?

  private func ensureContentInsetWrapper() {
    guard let chrome = contentChromeView else { return }

    if let wrapper = contentInsetWrapper, wrapper.superview === chrome { return }

    chrome.subviews.forEach { sub in
      // Keep chrome itself style layers; remove embedded content and re-embed later.
      if sub !== contentInsetWrapper {
        sub.removeFromSuperview()
      }
    }

    // Create wrapper that respects containerInsets.
    let wrapper = UIView()
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    wrapper.backgroundColor = configuration.appearance.backgroundColor
    chrome.addSubview(wrapper)

    let insets = configuration.content.containerInsets
    // Convert directional insets to LTR physical insets for constraints; wrapper will be laid out in LTR by anchors anyway.
    wrapper.leadingAnchor.constraint(equalTo: chrome.leadingAnchor, constant: insets.leading).isActive = true
    wrapper.trailingAnchor.constraint(equalTo: chrome.trailingAnchor, constant: -insets.trailing).isActive = true
    wrapper.topAnchor.constraint(equalTo: chrome.topAnchor, constant: insets.top).isActive = true
    wrapper.bottomAnchor.constraint(equalTo: chrome.bottomAnchor, constant: -insets.bottom).isActive = true

    contentInsetWrapper = wrapper

    embedContent(into: wrapper)
  }

  /// Embed the current `content` into the given host.
  /// Currently used for `contentInsetWrapper` only.
  private func embedContent(into hostView: UIView) {
    if let oldVC = embeddedContentViewController {
      oldVC.willMove(toParent: nil)
      oldVC.view.removeFromSuperview()
      oldVC.removeFromParent()
    }

    embeddedContentView = nil
    embeddedContentViewController = nil
    hostView.subviews.forEach { $0.removeFromSuperview() }

    guard let content else { return }
    switch content {
    case let .uiView(view):
      view.translatesAutoresizingMaskIntoConstraints = false
      hostView.addSubview(view)
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: hostView.topAnchor),
        view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
        view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
      ])
      embeddedContentView = view
    case let .uiViewController(vc):
      let hostVC = ancestorViewController(for: hostContainer ?? hostView) ?? vc
      hostVC.addChild(vc)
      vc.view.translatesAutoresizingMaskIntoConstraints = false
      hostView.addSubview(vc.view)
      NSLayoutConstraint.activate([
        vc.view.topAnchor.constraint(equalTo: hostView.topAnchor),
        vc.view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
        vc.view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
        vc.view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
      ])
      vc.didMove(toParent: hostVC)
      embeddedContentViewController = vc
      embeddedContentView = vc.view

      if vc.view.backgroundColor == .clear || vc.view.backgroundColor == nil {
        vc.view.backgroundColor = configuration.content.fallbackBackgroundColor
      }
    }
  }

  private func transformForPhase(_ phase: PhaseKind, anchorVertical: AnchorVertical) -> CGAffineTransform {
    // Match the reference animation behavior:
    // - Before animation: shift presentation by its own height so that its relevant edge aligns with
    //   the anchor edge.
    // - During animation: transition to `.identity` so the final layout stays correct.
    let distance = presentationContainerView?.bounds.height ?? 0
    let yBase: CGFloat = (anchorVertical == .below) ? -distance : distance

    switch phase {
    case .show:
      let t = configuration.animation.show.translation
      return CGAffineTransform(translationX: t.dx, y: yBase)
        .scaledBy(x: configuration.animation.show.scale, y: configuration.animation.show.scale)
    case .dismiss:
      let t = configuration.animation.dismiss.translation
      return CGAffineTransform(translationX: t.dx, y: yBase)
        .scaledBy(x: configuration.animation.dismiss.scale, y: configuration.animation.dismiss.scale)
    }
  }

  private enum PhaseKind { case show, dismiss }

  private func reduceShowPhase() -> Configuration.Animation.Phase {
    switch configuration.animation.reduceMotionBehavior {
    case .immediateNoTransform:
      return .init(
        duration: 0.001,
        delay: 0,
        alphaFrom: 0,
        alphaTo: 1,
        translation: .init(dx: 0, dy: 0),
        scale: 1.0,
        useSpring: false
      )
    case .shortDuration:
      return .init(
        duration: min(configuration.animation.show.duration, 0.12),
        delay: 0,
        alphaFrom: 0,
        alphaTo: 1,
        translation: .init(dx: 0, dy: 0),
        scale: 1.0,
        useSpring: false
      )
    }
  }

  private func reduceDismissPhase() -> Configuration.Animation.Phase {
    switch configuration.animation.reduceMotionBehavior {
    case .immediateNoTransform:
      return .init(
        duration: 0.001,
        delay: 0,
        alphaFrom: 1,
        alphaTo: 0,
        translation: .init(dx: 0, dy: 0),
        scale: 1.0,
        useSpring: false
      )
    case .shortDuration:
      return .init(
        duration: min(configuration.animation.dismiss.duration, 0.12),
        delay: 0,
        alphaFrom: 1,
        alphaTo: 0,
        translation: .init(dx: 0, dy: 0),
        scale: 1.0,
        useSpring: false
      )
    }
  }

  private func animateShow(duration: TimeInterval, phase: Configuration.Animation.Phase, completion: @escaping () -> Void) {
    // Setup initial state.
    maskView?.alpha = configuration.mask.enabled ? phase.alphaFrom : 0
    contentChromeView?.alpha = configuration.appearance.alpha
    presentationContainerView?.alpha = 1

    UIView.animate(
      withDuration: duration,
      delay: phase.delay,
      options: [.curveEaseOut, .beginFromCurrentState]
    ) {
      self.maskView?.alpha = self.configuration.mask.enabled ? phase.alphaTo : 0
      self.presentationContainerView?.transform = .identity
      self.contentChromeView?.alpha = 1
    } completion: { _ in completion() }
  }

  // MARK: Reposition observers
  private var didRegisterObservers: Bool = false

  private func observeRepositionIfNeeded() {
    guard configuration.reposition.enabled, !didRegisterObservers else { return }
    didRegisterObservers = true

    if configuration.reposition.listenOrientationChanges {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleRepositionRequest),
        name: UIDevice.orientationDidChangeNotification,
        object: nil
      )
    }
  }

  private func removeRepositionObservers() {
    NotificationCenter.default.removeObserver(self)
    didRegisterObservers = false
  }

  @objc private func handleRepositionRequest() {
    guard isPresented else { return }
    guard configuration.interaction.allowDismissingDuringReposition || !isRepositioning else { return }
    recalculateAndReposition(animated: false, completion: nil)
  }

  // MARK: Helpers

  private func findHostContainer(for sourceView: UIView) -> UIView {
    if let provided = sourceView.superview { return provided }
    if let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
       let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view
    {
      return root
    }
    return sourceView
  }

  private func findDirectChild(of host: UIView?, containing view: UIView) -> UIView? {
    guard let host else { return nil }
    var v: UIView? = view
    while let cur = v, cur.superview != nil, cur.superview !== host {
      v = cur.superview
    }
    // Now either v.superview == host or v == host.
    if v === host { return nil }
    return v
  }

  private func ancestorViewController(for view: UIView) -> UIViewController? {
    var responder: UIResponder? = view
    while let next = responder?.next {
      responder = next
      if let vc = responder as? UIViewController { return vc }
    }
    return nil
  }

  private func cleanupOverlay() {
    maskView?.removeFromSuperview()
    presentationContainerView?.removeFromSuperview()
    maskView = nil
    presentationContainerView = nil
    contentChromeView = nil
    contentInsetWrapper = nil

    embeddedContentView?.removeFromSuperview()
    embeddedContentView = nil

    if let vc = embeddedContentViewController {
      vc.willMove(toParent: nil)
      vc.view.removeFromSuperview()
      vc.removeFromParent()
      embeddedContentViewController = nil
    }
  }
}

private extension UIViewController {
  func loadViewIfNeeded() {
    _ = self.view
  }
}
