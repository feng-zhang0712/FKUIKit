import UIKit

/// High-performance blur view for iOS with both system hardware blur and fully custom Core Image blur.
///
/// `FKBlurView` is designed as a drop-in replacement for `UIVisualEffectView`:
/// - For **dynamic 60fps blur**, use `.system(...)` backend (hardware accelerated).
/// - For **fully custom parameters** (radius/saturation/brightness/tint), use `.custom(...)`.
///   In `.static` mode it blurs once for maximum performance; in `.dynamic` mode it refreshes using a
///   downsampled snapshot pipeline and a display-link refresh loop.
@IBDesignable
public final class FKBlurView: UIView {
  // MARK: - Public

  /// Current blur configuration.
  ///
  /// Thread-safe: may be set from any thread; UI updates are dispatched to the main thread.
  public var configuration: FKBlurConfiguration = FKBlur.defaultConfiguration {
    didSet { applyConfigurationAsync() }
  }

  /// The view used as the snapshot source for `.custom` backend.
  ///
  /// If `nil`, `superview` is used.
  ///
  /// - Important: Set this to the background container you want to blur, and avoid including `FKBlurView` itself
  ///   in the snapshot source to prevent recursive “blur of blur” artifacts.
  public weak var blurSourceView: UIView? {
    didSet { scheduleRefresh() }
  }

  /// Optional mask path defining the blurred region.
  ///
  /// If set, the blur content is clipped using a `CAShapeLayer` mask.
  public var maskPath: UIBezierPath? {
    didSet { updateMask() }
  }

  /// Sets a rounded-rect mask (in addition to `layer.cornerRadius`), avoiding edge artifacts when using `.custom`.
  @IBInspectable public var maskedCornerRadius: CGFloat = 0 {
    didSet { updateMask() }
  }

  /// Invalidates cached custom-blur output and schedules a new snapshot when source pixels change without layout
  /// (for example after updating an image or label behind a `.static` blur).
  ///
  /// No-op for `.system` backend.
  public func invalidateBlurContent() {
    guard case .custom = configuration.backend else { return }
    imageView.image = nil
    if UIAccessibility.isReduceTransparencyEnabled {
      applyReduceTransparencyOpaqueFill()
    } else {
      scheduleRefresh()
    }
  }

  // MARK: Interface Builder

  /// IB-only: 0 = system, 1 = custom.
  @IBInspectable public var ibBackend: Int = 0 {
    didSet { syncFromIB() }
  }

  /// IB-only: system style index mapped to `FKBlurConfiguration.SystemStyle.allCases`.
  @IBInspectable public var ibSystemStyleIndex: Int =  FKBlurConfiguration.SystemStyle.allCases.firstIndex(of: .systemMaterial) ?? 0 {
    didSet { syncFromIB() }
  }

  /// IB-only: 0 = static, 1 = dynamic.
  @IBInspectable public var ibMode: Int = 1 {
    didSet { syncFromIB() }
  }

  /// IB-only: overall opacity (0...1).
  @IBInspectable public var ibOpacity: CGFloat = 1.0 {
    didSet { syncFromIB() }
  }

  /// IB-only: custom blur radius.
  @IBInspectable public var ibBlurRadius: CGFloat = 20 {
    didSet { syncFromIB() }
  }

  /// IB-only: custom saturation multiplier.
  @IBInspectable public var ibSaturation: CGFloat = 1.0 {
    didSet { syncFromIB() }
  }

  /// IB-only: custom brightness adjustment.
  @IBInspectable public var ibBrightness: CGFloat = 0.0 {
    didSet { syncFromIB() }
  }

  /// IB-only: tint overlay color (only used by custom backend).
  @IBInspectable public var ibTintColor: UIColor? {
    didSet { syncFromIB() }
  }

  /// IB-only: tint opacity (0...1).
  @IBInspectable public var ibTintOpacity: CGFloat = 0.0 {
    didSet { syncFromIB() }
  }

  /// IB-only: custom pipeline downsample factor (>= 1).
  @IBInspectable public var ibDownsampleFactor: CGFloat = 4 {
    didSet { syncFromIB() }
  }

  /// IB-only: custom fill when *Reduce Transparency* is on and backend is custom (`nil` = system secondary background).
  @IBInspectable public var ibReduceTransparencyFallbackColor: UIColor? {
    didSet { syncFromIB() }
  }

  // MARK: - Lifecycle

  /// Creates a blur view with the given frame.
  ///
  /// - Parameter frame: Initial frame rectangle of the view.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  /// Creates a blur view from an Interface Builder archive.
  ///
  /// - Parameter coder: The decoder to read data from.
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  deinit {
    if let reduceTransparencyObserver {
      NotificationCenter.default.removeObserver(reduceTransparencyObserver)
    }
  }

  /// Prepares the view for rendering inside Interface Builder.
  public override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    syncFromIB()
    applyConfiguration()
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    updateRefreshLoop()
    scheduleRefresh()
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    scheduleRefresh()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    systemEffectView.frame = bounds
    imageView.frame = bounds
    tintOverlayView.frame = bounds
    updateMask()
    scheduleRefresh()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    // Re-apply system effect to react to light/dark changes.
    if case .system = configuration.backend {
      applyConfigurationAsync()
    } else if UIAccessibility.isReduceTransparencyEnabled {
      applyReduceTransparencyOpaqueFill()
    } else {
      scheduleRefresh()
    }
  }

  // MARK: - Private

  private let systemEffectView = UIVisualEffectView(effect: nil)
  private let imageView: UIImageView = {
    let v = UIImageView()
    v.contentMode = .scaleToFill
    v.clipsToBounds = true
    return v
  }()

  private let tintOverlayView: UIView = {
    let v = UIView()
    v.isUserInteractionEnabled = false
    v.backgroundColor = .clear
    return v
  }()

  private var displayLink: CADisplayLink?
  private var pendingRefresh = false
  /// NotificationCenter token; stored as `nonisolated(unsafe)` so it can be removed from `deinit` under Swift 6 isolation rules.
  nonisolated(unsafe) private var reduceTransparencyObserver: NSObjectProtocol?

  /// Tracks custom-blur pipeline inputs so `.static` mode can invalidate snapshots only when radius/material inputs change (not when only `opacity` / `preferredFramesPerSecond` change).
  private var lastAppliedCustomPipelineKey: (FKBlurConfiguration.Mode, FKBlurConfiguration.Backend, CGFloat)?

  private func commonInit() {
    isUserInteractionEnabled = false
    clipsToBounds = false

    addSubview(systemEffectView)
    addSubview(imageView)
    addSubview(tintOverlayView)

    systemEffectView.isUserInteractionEnabled = false
    imageView.isUserInteractionEnabled = false

    reduceTransparencyObserver = NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleReduceTransparencyStatusChanged()
    }

    // Default: show system path until config applied.
    applyConfigurationAsync()
  }

  private func applyConfigurationAsync() {
    if Thread.isMainThread {
      applyConfiguration()
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.applyConfiguration()
      }
    }
  }

  private func applyConfiguration() {
    alpha = max(0, min(configuration.opacity, 1))

    switch configuration.backend {
    case .system(let style):
      lastAppliedCustomPipelineKey = nil
      // Hardware path: always best for dynamic performance.
      systemEffectView.effect = UIBlurEffect(style: style.uiBlurEffectStyle)
      systemEffectView.isHidden = false
      imageView.isHidden = true
      tintOverlayView.isHidden = true
      stopDisplayLink()

    case .custom:
      // Custom path: render blurred snapshots into `imageView`.
      systemEffectView.effect = nil
      systemEffectView.isHidden = true
      imageView.isHidden = false
      tintOverlayView.isHidden = true
      let pipelineKey = (configuration.mode, configuration.backend, configuration.downsampleFactor)
      if configuration.mode == .static {
        if lastAppliedCustomPipelineKey.map({ $0 != pipelineKey }) ?? true {
          imageView.image = nil
        }
      }
      lastAppliedCustomPipelineKey = pipelineKey
      updateRefreshLoop()
      scheduleRefresh()
    }
  }

  private func updateRefreshLoop() {
    let needsLink: Bool = {
      guard window != nil else { return false }
      guard case .custom = configuration.backend else { return false }
      if UIAccessibility.isReduceTransparencyEnabled { return false }
      return configuration.mode == .dynamic
    }()

    if needsLink {
      if displayLink == nil {
        // Drive refresh in sync with screen vsync for stable frame pacing.
        let link = CADisplayLink(target: self, selector: #selector(onDisplayLinkTick))
        link.preferredFramesPerSecond = max(1, configuration.preferredFramesPerSecond)
        link.add(to: .main, forMode: .common)
        displayLink = link
      } else {
        // Allow changing the refresh rate at runtime.
        displayLink?.preferredFramesPerSecond = max(1, configuration.preferredFramesPerSecond)
      }
    } else {
      stopDisplayLink()
    }
  }

  private func stopDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }

  private func scheduleRefresh() {
    guard case .custom = configuration.backend else { return }
    guard window != nil else { return }

    if UIAccessibility.isReduceTransparencyEnabled {
      applyReduceTransparencyOpaqueFill()
      return
    }

    imageView.backgroundColor = nil

    if configuration.mode == .static {
      // Static mode: render once and keep the image forever.
      if imageView.image == nil {
        refreshCustomBlur()
      }
    } else {
      // Dynamic mode: mark as pending. The display link tick performs the actual expensive work.
      pendingRefresh = true
    }
  }

  @objc private func onDisplayLinkTick() {
    guard pendingRefresh else { return }
    pendingRefresh = false
    refreshCustomBlur()
  }

  private func refreshCustomBlur() {
    guard case .custom(let parameters) = configuration.backend else { return }

    if UIAccessibility.isReduceTransparencyEnabled {
      applyReduceTransparencyOpaqueFill()
      return
    }

    imageView.backgroundColor = nil

    let src = blurSourceView ?? superview
    guard let sourceView = src else { return }
    guard bounds.width > 1, bounds.height > 1 else { return }

    // Snapshot the source view and crop to our bounds (in sourceView coordinates).
    // This keeps the blur region local and avoids filtering the entire screen unnecessarily.
    guard let snapshot = snapshotImage(from: sourceView) else { return }
    let cropRectInSnapshot = convert(bounds, to: sourceView)
    let cropped = snapshot.fk_cropped(to: cropRectInSnapshot, snapshotScale: snapshot.scale)

    // Downsample before filtering to reduce bandwidth and keep dynamic updates smooth.
    let downsample = max(1, configuration.downsampleFactor)
    let blurred = cropped?.fk_blurred(parameters: parameters, downsampleFactor: downsample)
    imageView.image = blurred
  }

  private func applyReduceTransparencyOpaqueFill() {
    imageView.image = nil
    let base = configuration.reduceTransparencyFallbackColor ?? .secondarySystemBackground
    imageView.backgroundColor = base.resolvedColor(with: traitCollection)
  }

  private func handleReduceTransparencyStatusChanged() {
    updateRefreshLoop()
    guard case .custom = configuration.backend else { return }
    if UIAccessibility.isReduceTransparencyEnabled {
      applyReduceTransparencyOpaqueFill()
    } else {
      imageView.backgroundColor = nil
      scheduleRefresh()
    }
  }

  private func snapshotImage(from view: UIView) -> UIImage? {
    // Prefer drawHierarchy for correctness; keep scale modest for performance in dynamic mode.
    let scale: CGFloat = {
      // Dynamic refresh: force a low snapshot scale and rely on downsampling.
      // Static refresh: allow using the screen scale for sharper results.
      if configuration.mode == .dynamic { return 1 } // dynamic path relies on downsample anyway
      return window?.screen.scale ?? UIScreen.main.scale
    }()

    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
    return renderer.image { ctx in
      // drawHierarchy is usually faster for UIVisualEffect/backed views than layer.render.
      if !view.drawHierarchy(in: view.bounds, afterScreenUpdates: false) {
        view.layer.render(in: ctx.cgContext)
      }
    }
  }

  private func updateMask() {
    let path: UIBezierPath? = {
      if let p = maskPath { return p }
      if maskedCornerRadius > 0 { return UIBezierPath(roundedRect: bounds, cornerRadius: maskedCornerRadius) }
      return nil
    }()

    if let path {
      let layer = (self.layer.mask as? CAShapeLayer) ?? CAShapeLayer()
      layer.frame = bounds
      layer.path = path.cgPath
      self.layer.mask = layer
    } else {
      self.layer.mask = nil
    }
  }

  private func syncFromIB() {
    // Map IBInspectable integers/colors into the type-safe configuration model.
    let mode: FKBlurConfiguration.Mode = (ibMode == 0) ? .static : .dynamic
    let opacity = max(0, min(ibOpacity, 1))
    let downsample = max(1, ibDownsampleFactor)

    if ibBackend == 0 {
      let styles = FKBlurConfiguration.SystemStyle.allCases
      let idx = max(0, min(ibSystemStyleIndex, styles.count - 1))
      configuration = FKBlurConfiguration(
        mode: mode,
        backend: .system(style: styles[idx]),
        opacity: opacity,
        downsampleFactor: downsample,
        preferredFramesPerSecond: configuration.preferredFramesPerSecond,
        reduceTransparencyFallbackColor: ibReduceTransparencyFallbackColor
      )
    } else {
      let params = FKBlurConfiguration.CustomParameters(
        blurRadius: ibBlurRadius,
        saturation: ibSaturation,
        brightness: ibBrightness,
        tintColor: ibTintColor,
        tintOpacity: max(0, min(ibTintOpacity, 1))
      )
      configuration = FKBlurConfiguration(
        mode: mode,
        backend: .custom(parameters: params),
        opacity: opacity,
        downsampleFactor: downsample,
        preferredFramesPerSecond: configuration.preferredFramesPerSecond,
        reduceTransparencyFallbackColor: ibReduceTransparencyFallbackColor
      )
    }
  }
}

// MARK: - Helpers

private extension UIImage {
  func fk_cropped(to rect: CGRect, snapshotScale: CGFloat) -> UIImage? {
    guard let cgImage else { return nil }
    let scaled = CGRect(
      x: rect.origin.x * snapshotScale,
      y: rect.origin.y * snapshotScale,
      width: rect.size.width * snapshotScale,
      height: rect.size.height * snapshotScale
    ).integral
    guard scaled.width > 0, scaled.height > 0 else { return nil }
    guard let out = cgImage.cropping(to: scaled) else { return nil }
    return UIImage(cgImage: out, scale: snapshotScale, orientation: imageOrientation)
  }
}

