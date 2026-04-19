//
// FKButton.swift
//
// Custom-layout button supporting multi-state title/subtitle, multi-slot images, and custom views.
// Includes throttled primary actions, expanded hit testing, long-press callbacks, configurable loading,
// linear gradient backgrounds, per-state `Appearance`, `FKButton.GlobalStyle`, and IB attributes.
//

import UIKit

/// A `UIControl`-subclass button with explicit per-state models (title, images, appearance).
///
/// Highlights:
/// - **Content**: `content` drives layout (text only, image only, text+image, or embedded custom view).
/// - **Appearance**: `setAppearance(_:for:)` / `setAppearances(_:)` for colors, gradient, border, shadow, insets, highlight feedback.
/// - **Interaction**: `minimumTapInterval` throttles primary actions; `hitTestEdgeInsets` enlarges the tap target;
///   `onLongPressBegan` / `onLongPressRepeatTick` / `onLongPressEnded` for long-press workflows.
/// - **Content alignment**: `contentHorizontalAlignment` / `contentVerticalAlignment` (inherited from `UIControl`) position
///   the built-in title/image stack inside `Appearance.contentInsets`; defaults are `.center` / `.center` (typical title+image grouping).
///   Use `.fill` when the stack should span the padded content area edge-to-edge.
/// - **Loading**: `setLoading(_:presentation:)` with `LoadingPresentationStyle` (dimmed overlay or hidden content + status text).
/// - **Global defaults**: `FKButton.GlobalStyle` supplies values copied into each new instance during `commonInit`.
///
/// Subclasses may override `layoutSubviews`, `intrinsicContentSize`, `point(inside:with:)`, etc. (`open`).
@IBDesignable open class FKButton: UIControl {
  private typealias StateKey = UInt
  private typealias StatefulValues<T> = [StateKey: T]

  // MARK: - Nested types (axis & slots)

  /// The layout axis for the button content (affects how image and title are arranged).
  ///
  /// - `horizontal`: laid out horizontally.
  /// - `vertical`: laid out vertically.
  ///
  /// Under `.textAndImage`, it determines relative placement of text and image.
  /// Other `content.kind` values have smaller or no effect.
  public enum Axis {
    case horizontal
    case vertical
  }
  
  /// Image slots (semantics for `setImage` / `setLeadingImage` / `setTrailingImage`).
  ///
  /// - `center`: centered image slot (used only when needed by `.imageOnly` or some `.textAndImage` cases).
  /// - `leading`: image slot placed adjacent to the title on the leading side (maps to different physical directions across `axis`).
  /// - `trailing`: image slot placed adjacent to the title on the trailing side (maps to different physical directions across `axis`).
  public enum ImageSlot {
    case center
    case leading
    case trailing
  }

  /// Resolves state lookup candidates for stateful maps.
  /// Return order must be from high to low priority.
  public typealias StateResolutionProvider = (_ isEnabled: Bool, _ isSelected: Bool, _ isHighlighted: Bool) -> [UIControl.State]

  // MARK: - Configuration

  /// Content composition model. Updating this rebinds internal subviews immediately.
  public var content: FKButton.Content {
    didSet {
      requestVisualRefresh(rebuildContentLayout: true)
    }
  }
  
  /// Layout axis for the internal `UIStackView`.
  public var axis: Axis = .horizontal {
    didSet { applyAxis() }
  }

  /// Optional custom provider for state resolution order.
  /// When `nil`, the default order is used: disabled -> selected -> highlighted -> normal.
  public var stateResolutionProvider: StateResolutionProvider? {
    didSet { requestVisualRefresh() }
  }

  // MARK: - Content subviews & state storage

  /// Hosts `stackView`; `Appearance.contentInsets` pin this view to `FKButton` edges so `contentHorizontalAlignment` /
  /// `contentVerticalAlignment` can position the stack inside without fighting appearance insets.
  private let contentContainerView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.isUserInteractionEnabled = false
    v.backgroundColor = .clear
    return v
  }()

  private let stackView = UIStackView()
  private var contentAlignmentConstraints: [NSLayoutConstraint] = []

  /// Created only when `content.kind` is `.textOnly` / `.textAndImage` (added via the title container).
  /// When switching to `.imageOnly` / `.custom`, it is released via `releaseTitleLabel()`.
  public private(set) var titleLabel: UILabel?
  
  /// Subtitle label shown below `titleLabel`.
  /// Layout: subtitle is always constrained beneath `titleLabel`.
  public private(set) var subtitleLabel: UILabel?
  
  /// Title container (subtitle is always below the title).
  private var titleContainerView: UIView?
  
  /// Created only when the corresponding slot is needed.
  /// Recovered via `clearImageSlot(_:)` / `releaseAllImageSlots()`.
  public private(set) var imageView: UIImageView?
  public private(set) var leadingImageView: UIImageView?
  public private(set) var trailingImageView: UIImageView?

  private var titleLabelTopConstraint: NSLayoutConstraint?
  private var titleLabelLeadingConstraint: NSLayoutConstraint?
  private var titleLabelTrailingConstraint: NSLayoutConstraint?
  private var titleLabelBottomConstraintToContainer: NSLayoutConstraint?
  private var subtitleTopConstraint: NSLayoutConstraint?
  private var subtitleLeadingConstraint: NSLayoutConstraint?
  private var subtitleTrailingConstraint: NSLayoutConstraint?
  private var subtitleBottomConstraint: NSLayoutConstraint?

  /// Created only for `Content.Kind.custom`.
  /// Released via `releaseCustomContentHost()`.
  private var customContentHost: FKButtonCustomContentHostView?
  private var embeddedCustomContentView: UIView?

  private var appearanceByState: StatefulValues<Appearance> = [UIControl.State.normal.rawValue: .default]

  private var titleByState: StatefulValues<LabelAttributes> = [:]
  private var subtitleByState: StatefulValues<LabelAttributes> = [:]
  private var customContentByState: StatefulValues<CustomContent> = [:]

  /// Store state data per slot.
  /// No pre-allocation (consistent with on-demand view creation); written on the first `setImage`.
  private var imagesBySlotAndState: [ImageSlot: StatefulValues<ImageAttributes>] = [:]
  
  private var imageConstraints: [ObjectIdentifier: [NSLayoutConstraint]] = [:]
  
  private var topConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  private var trailingConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  private var batchUpdateDepth = 0
  private var needsVisualRefresh = false
  private var needsContentLayoutRefresh = false

  // MARK: - Tap throttle / hit area / loading / long press

  /// Ignores duplicate `touchUpInside` / `primaryActionTriggered` deliveries within this interval (seconds). `0` disables throttling.
  ///
  /// Throttling is applied in `sendAction(_:to:for:)` because UIKit often dispatches `UIAction` / target-action by calling
  /// `sendAction` directly, without going through `sendActions(for:)` (so overriding only `sendActions` would not intercept taps).
  public var minimumTapInterval: TimeInterval = 1.0
  private var lastPrimaryActionDeliveryTime: CFAbsoluteTime = 0
  /// `UIEvent.timestamp` of the last accepted user interaction wave (touches / presses); used to allow every `sendAction` in the same event.
  private var lastThrottledInteractionEventTimestamp: TimeInterval = -1

  /// Expands or shrinks the tappable rect in `point(inside:with:)` without changing layout.
  /// Negative insets enlarge the target (same semantics as `CGRect.inset(by:)` with negative edges).
  public var hitTestEdgeInsets: UIEdgeInsets = .zero

  /// When `true`, applies `disabledDimmingAlpha` on top of resolved appearance while `isEnabled == false` (skipped while `isLoading`).
  public var automaticallyDimsWhenDisabled: Bool = true
  /// Multiplier applied to resolved appearance alpha when `automaticallyDimsWhenDisabled` is active.
  public var disabledDimmingAlpha: CGFloat = 0.55

  /// `true` while `setLoading(true, …)` is active; primary actions are suppressed and interaction is forced off until cleared.
  public private(set) var isLoading: Bool = false
  /// Spinner + optional status row layout while loading. Ignored until the next time loading becomes active unless you call `applyLoadingPresentation(_:)`.
  public var loadingPresentationStyle: LoadingPresentationStyle = .overlay(dimmedContentAlpha: 0.35)
  /// When non-`nil`, sets `UIActivityIndicatorView.color` for the built-in loading spinner. When `nil`, the system default tint is used.
  public var loadingActivityIndicatorColor: UIColor? {
    didSet { syncLoadingActivityIndicatorColor() }
  }
  private var userInteractionEnabledBeforeLoading: Bool = true

  /// Minimum finger-down duration before `UILongPressGestureRecognizer` enters `.began`.
  public var longPressMinimumDuration: TimeInterval = 0.5 {
    didSet { longPressRecognizer.minimumPressDuration = longPressMinimumDuration }
  }

  /// Interval between `onLongPressRepeatTick` callbacks after recognition begins. `0` disables repeat ticks.
  public var longPressRepeatTickInterval: TimeInterval = 0.1

  /// Invoked when a long press is first recognized (after `longPressMinimumDuration`).
  public var onLongPressBegan: (() -> Void)?
  /// Invoked when the long-press gesture ends, fails, or is cancelled.
  public var onLongPressEnded: (() -> Void)?
  /// Invoked once when recognition begins and on each timer tick while the finger stays down (see `longPressRepeatTickInterval`).
  public var onLongPressRepeatTick: (() -> Void)?

  private let backgroundGradientLayer = CAGradientLayer()
  private let loadingOverlayHost = UIView()
  private let loadingRowStack = UIStackView()
  private let loadingMessageLabel = UILabel()
  private let loadingIndicator = UIActivityIndicatorView(style: .medium)
  private let longPressRecognizer = UILongPressGestureRecognizer()
  /// `Timer` is not `Sendable`; only created/invalidated on the main run loop for long-press repeat.
  private nonisolated(unsafe) var longPressRepeatTimer: Timer?

  private static let paddedImageCache = NSCache<NSString, UIImage>()
  
  /// Creates a button with default content (`.textOnly`).
  public init() {
    self.content = .default
    super.init(frame: .zero)
    commonInit()
  }
  
  /// Creates a button with a custom frame and default content (`.textOnly`).
  public override init(frame: CGRect) {
    self.content = .default
    super.init(frame: frame)
    commonInit()
  }
  
  /// Creates a button with an initial content model.
  public init(content: FKButton.Content) {
    self.content = content
    super.init(frame: .zero)
    commonInit()
  }
  
  /// Storyboard/XIB initializer.
  public required init?(coder: NSCoder) {
    self.content = .default
    super.init(coder: coder)
    commonInit()
  }
  
  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .button

    stackView.spacing = 0
    stackView.alignment = .center
    stackView.isUserInteractionEnabled = false
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(contentContainerView)
    contentContainerView.addSubview(stackView)

    topConstraint = contentContainerView.topAnchor.constraint(equalTo: topAnchor)
    leadingConstraint = contentContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
    trailingConstraint = contentContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
    bottomConstraint = contentContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    topConstraint?.isActive = true
    leadingConstraint?.isActive = true
    trailingConstraint?.isActive = true
    bottomConstraint?.isActive = true

    layer.insertSublayer(backgroundGradientLayer, at: 0)
    backgroundGradientLayer.zPosition = -1
    configureLoadingOverlay()
    longPressRecognizer.addTarget(self, action: #selector(handleLongPress(_:)))
    longPressRecognizer.minimumPressDuration = longPressMinimumDuration
    longPressRecognizer.cancelsTouchesInView = false
    addGestureRecognizer(longPressRecognizer)
    applyFactoryDefaultsFromGlobalStyle()

    applyAxis()
    applyContentLayout()
    applyTextForCurrentState()
    applyImagesForCurrentState()
    applyCustomContentForCurrentState()
    applyAppearanceForCurrentState()

    if let appearances = FKButton.GlobalStyle.defaultAppearances {
      setAppearances(appearances)
    }
    FKButton.GlobalStyle.applyPerNewButton?(self)

    super.contentHorizontalAlignment = .center
    super.contentVerticalAlignment = .center
    applyContentAlignmentLayout()
  }

  // MARK: - Public — Appearance

  /// Register an appearance for the given state.
  /// If the current state matches, it is applied immediately.
  public func setAppearance(_ appearance: Appearance, for state: UIControl.State) {
    appearanceByState[state.rawValue] = appearance
    requestVisualRefresh()
  }
  
  /// Reads the registered appearance for an exact state key.
  public func appearance(for state: UIControl.State) -> Appearance? {
    appearanceByState[state.rawValue]
  }

  /// Apply an appearance bundle for normal/selected/highlighted/disabled.
  public func setAppearances(_ appearances: StateAppearances) {
    performBatchUpdates {
      setAppearance(appearances.normal, for: .normal)
      setAppearance(appearances.selected, for: .selected)
      setAppearance(appearances.highlighted, for: .highlighted)
      setAppearance(appearances.disabled, for: .disabled)
    }
  }

  /// Convenience API to register title values for common states in one call.
  public func setTitles(normal: LabelAttributes?, selected: LabelAttributes? = nil, highlighted: LabelAttributes? = nil, disabled: LabelAttributes? = nil) {
    performBatchUpdates {
      setTitle(normal, for: .normal)
      setTitle(selected ?? normal, for: .selected)
      setTitle(highlighted ?? selected ?? normal, for: .highlighted)
      setTitle(disabled ?? normal, for: .disabled)
    }
  }

  /// Convenience API to register subtitle values for common states in one call.
  public func setSubtitles(normal: LabelAttributes?, selected: LabelAttributes? = nil, highlighted: LabelAttributes? = nil, disabled: LabelAttributes? = nil) {
    performBatchUpdates {
      setSubtitle(normal, for: .normal)
      setSubtitle(selected ?? normal, for: .selected)
      setSubtitle(highlighted ?? selected ?? normal, for: .highlighted)
      setSubtitle(disabled ?? normal, for: .disabled)
    }
  }

  /// Convenience API to register center-image values for common states in one call.
  public func setImages(normal: ImageAttributes?, selected: ImageAttributes? = nil, highlighted: ImageAttributes? = nil, disabled: ImageAttributes? = nil) {
    performBatchUpdates {
      setImage(normal, for: .normal)
      setImage(selected ?? normal, for: .selected)
      setImage(highlighted ?? selected ?? normal, for: .highlighted)
      setImage(disabled ?? normal, for: .disabled)
    }
  }

  /// Convenience API to register leading-image values for common states in one call.
  public func setLeadingImages(normal: ImageAttributes?, selected: ImageAttributes? = nil, highlighted: ImageAttributes? = nil, disabled: ImageAttributes? = nil) {
    performBatchUpdates {
      setLeadingImage(normal, for: .normal)
      setLeadingImage(selected ?? normal, for: .selected)
      setLeadingImage(highlighted ?? selected ?? normal, for: .highlighted)
      setLeadingImage(disabled ?? normal, for: .disabled)
    }
  }

  /// Convenience API to register trailing-image values for common states in one call.
  public func setTrailingImages(normal: ImageAttributes?, selected: ImageAttributes? = nil, highlighted: ImageAttributes? = nil, disabled: ImageAttributes? = nil) {
    performBatchUpdates {
      setTrailingImage(normal, for: .normal)
      setTrailingImage(selected ?? normal, for: .selected)
      setTrailingImage(highlighted ?? selected ?? normal, for: .highlighted)
      setTrailingImage(disabled ?? normal, for: .disabled)
    }
  }

  /// Convenience API to register custom-content values for common states in one call.
  public func setCustomContents(normal: CustomContent?, selected: CustomContent? = nil, highlighted: CustomContent? = nil, disabled: CustomContent? = nil) {
    performBatchUpdates {
      setCustomContent(normal, for: .normal)
      setCustomContent(selected ?? normal, for: .selected)
      setCustomContent(highlighted ?? selected ?? normal, for: .highlighted)
      setCustomContent(disabled ?? normal, for: .disabled)
    }
  }

  /// Applies multiple stateful updates and refreshes rendering once.
  public func performBatchUpdates(_ updates: () -> Void) {
    batchUpdateDepth += 1
    updates()
    batchUpdateDepth -= 1
    if batchUpdateDepth == 0, needsVisualRefresh {
      needsVisualRefresh = false
      flushPendingRefresh()
    }
  }

  // MARK: - Public — Title & subtitle

  /// Registers the main title row for an exact `UIControl.State` key.
  /// Pass `nil` to remove registration for that key.
  public func setTitle(_ attributes: LabelAttributes?, for state: UIControl.State) {
    if let attributes {
      titleByState[state.rawValue] = attributes
    } else {
      titleByState.removeValue(forKey: state.rawValue)
    }
    requestVisualRefresh()
  }
  
  /// Reads the registered title attributes for an exact state key.
  public func title(for state: UIControl.State) -> LabelAttributes? {
    titleByState[state.rawValue]
  }
  
  /// Registers the subtitle row for an exact `UIControl.State` key.
  public func setSubtitle(_ attributes: LabelAttributes?, for state: UIControl.State) {
    if let attributes {
      subtitleByState[state.rawValue] = attributes
    } else {
      subtitleByState.removeValue(forKey: state.rawValue)
    }
    requestVisualRefresh()
  }
  
  /// Reads the registered subtitle attributes for an exact state key.
  public func subtitle(for state: UIControl.State) -> LabelAttributes? {
    subtitleByState[state.rawValue]
  }

  // MARK: - Public — Images

  /// Set the centered image slot (`.center`).
  public func setImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, for: state, slot: .center)
    requestVisualRefresh()
  }
  
  /// Set the leading-side image slot (relative to the title's leading side,
  /// mapped to concrete geometry based on `axis` and layout direction).
  public func setLeadingImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, for: state, slot: .leading)
    requestVisualRefresh()
  }
  
  /// Set the trailing-side image slot.
  public func setTrailingImage(_ image: ImageAttributes?, for state: UIControl.State) {
    setImage(image, for: state, slot: .trailing)
    requestVisualRefresh()
  }
  
  /// Read the registered image for a given slot/state pair.
  public func image(for state: UIControl.State, slot: ImageSlot) -> ImageAttributes? {
    imagesBySlotAndState[slot]?[state.rawValue]
  }

  // MARK: - Public — Custom content

  /// Requires `content.kind == .custom`. Use `nil` to clear this state.
  public func setCustomContent(_ content: CustomContent?, for state: UIControl.State) {
    if let content {
      customContentByState[state.rawValue] = content
    } else {
      customContentByState.removeValue(forKey: state.rawValue)
    }
    requestVisualRefresh()
  }

  /// Reads the registered custom content for an exact state key.
  public func customContent(for state: UIControl.State) -> CustomContent? {
    customContentByState[state.rawValue]
  }
  
  // MARK: - Layout

  open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
    get { super.contentHorizontalAlignment }
    set {
      guard newValue != super.contentHorizontalAlignment else { return }
      super.contentHorizontalAlignment = newValue
      applyContentAlignmentLayout()
    }
  }

  open override var contentVerticalAlignment: UIControl.ContentVerticalAlignment {
    get { super.contentVerticalAlignment }
    set {
      guard newValue != super.contentVerticalAlignment else { return }
      super.contentVerticalAlignment = newValue
      applyContentAlignmentLayout()
    }
  }

  open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      applyContentAlignmentLayout()
    }
  }

  /// Intrinsic size based on resolved content plus `Appearance.contentInsets`.
  open override var intrinsicContentSize: CGSize {
    let appearance = resolveAppearance()
    let insets = appearance.contentInsets
    let size = stackView.systemLayoutSizeFitting(
      CGSize(
        width: UIView.layoutFittingCompressedSize.width,
        height: UIView.layoutFittingCompressedSize.height
      ),
      withHorizontalFittingPriority: .defaultLow,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(
      width: size.width + insets.leading + insets.trailing,
      height: size.height + insets.top + insets.bottom
    )
  }
  
  /// Keeps corner radius and shadow path in sync with current bounds.
  open override func layoutSubviews() {
    super.layoutSubviews()
    let appearance = resolveAppearance()
    applyCornerMetrics(using: appearance)
    updateShadowPath(using: appearance)
    backgroundGradientLayer.frame = bounds
    backgroundGradientLayer.cornerRadius = layer.cornerRadius
    backgroundGradientLayer.cornerCurve = layer.cornerCurve
    backgroundGradientLayer.maskedCorners = layer.maskedCorners
  }
  
  /// Expands hit-testing using appearance, active image outsets, and `hitTestEdgeInsets`.
  open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    hitTestingBounds().contains(point)
  }
  
  // MARK: - State
  
  open override var isEnabled: Bool {
    didSet {
      requestVisualRefresh()
    }
  }
  
  open override var isSelected: Bool {
    didSet {
      requestVisualRefresh()
      accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
  }
  
  open override var isHighlighted: Bool {
    didSet {
      requestVisualRefresh()
      let appearance = resolveAppearance()
      let feedback = appearance.interaction.isHighlightFeedbackEnabled
      UIView.animate(withDuration: 0.12) {
        self.alpha = self.resolvedAlpha(for: appearance) * self.disabledVisualMultiplier()
        self.transform = (self.isHighlighted && feedback)
          ? CGAffineTransform(scaleX: appearance.interaction.pressedScale, y: appearance.interaction.pressedScale)
          : .identity
      }
    }
  }

  open override func sendActions(for controlEvents: UIControl.Event) {
    guard !isLoading else { return }
    super.sendActions(for: controlEvents)
  }

  open override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
    guard !isLoading else { return }
    if shouldSuppressThrottledPrimaryAction(for: event) {
      return
    }
    super.sendAction(action, to: target, for: event)
  }

  open override func sendAction(_ action: UIAction) {
    guard !isLoading else { return }
    // `addAction(_:for:)` / UIAction dispatch commonly uses this overload without a `UIEvent`.
    if shouldSuppressThrottledPrimaryAction(for: nil) {
      return
    }
    super.sendAction(action)
  }

  /// Returns `true` if this `sendAction` should be dropped due to `minimumTapInterval`.
  private func shouldSuppressThrottledPrimaryAction(for event: UIEvent?) -> Bool {
    guard minimumTapInterval > 0 else { return false }
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

  /// Shows the loading chrome, blocks interaction, and optionally updates `loadingPresentationStyle` for this transition.
  public func setLoading(_ loading: Bool, presentation: LoadingPresentationStyle? = nil) {
    guard loading != isLoading else { return }
    if let p = presentation {
      loadingPresentationStyle = p
    }
    if loading {
      userInteractionEnabledBeforeLoading = isUserInteractionEnabled
      isLoading = true
      isUserInteractionEnabled = false
      applyLoadingChromeForCurrentStyle()
      loadingOverlayHost.isHidden = false
      loadingIndicator.startAnimating()
    } else {
      isLoading = false
      isUserInteractionEnabled = userInteractionEnabledBeforeLoading
      loadingIndicator.stopAnimating()
      loadingOverlayHost.isHidden = true
      stackView.isHidden = false
      stackView.alpha = 1
      loadingMessageLabel.text = nil
      loadingMessageLabel.isHidden = true
      accessibilityValue = nil
    }
    requestVisualRefresh()
  }

  /// Updates loading visuals while already loading (or stores the style for the next `setLoading(true)`).
  public func applyLoadingPresentation(_ style: LoadingPresentationStyle) {
    loadingPresentationStyle = style
    if isLoading {
      applyLoadingChromeForCurrentStyle()
    }
  }

  /// Runs `operation` with loading enabled, then restores interaction and any temporary `presentation` override.
  @MainActor
  public func performWhileLoading(
    presentation: LoadingPresentationStyle? = nil,
    operation: () async throws -> Void
  ) async rethrows {
    let previousStyle = loadingPresentationStyle
    if let p = presentation {
      loadingPresentationStyle = p
    }
    setLoading(true)
    defer {
      setLoading(false)
      loadingPresentationStyle = previousStyle
    }
    try await operation()
  }

  deinit {
    longPressRepeatTimer?.invalidate()
  }

  open override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    flushPendingRefresh()
  }

  private func applyFactoryDefaultsFromGlobalStyle() {
    minimumTapInterval = FKButton.GlobalStyle.minimumTapInterval
    longPressMinimumDuration = FKButton.GlobalStyle.longPressMinimumDuration
    longPressRepeatTickInterval = FKButton.GlobalStyle.longPressRepeatTickInterval
    automaticallyDimsWhenDisabled = FKButton.GlobalStyle.automaticallyDimsWhenDisabled
    disabledDimmingAlpha = FKButton.GlobalStyle.disabledDimmingAlpha
    longPressRecognizer.minimumPressDuration = longPressMinimumDuration
  }

  private func configureLoadingOverlay() {
    loadingOverlayHost.isUserInteractionEnabled = false
    loadingOverlayHost.backgroundColor = .clear
    loadingOverlayHost.translatesAutoresizingMaskIntoConstraints = false
    loadingOverlayHost.isHidden = true

    loadingRowStack.axis = .horizontal
    loadingRowStack.alignment = .center
    loadingRowStack.spacing = 8
    loadingRowStack.isUserInteractionEnabled = false
    loadingRowStack.translatesAutoresizingMaskIntoConstraints = false

    loadingMessageLabel.numberOfLines = 1
    loadingMessageLabel.textAlignment = .natural
    loadingMessageLabel.lineBreakMode = .byTruncatingTail
    loadingMessageLabel.isHidden = true

    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    loadingIndicator.hidesWhenStopped = true
    syncLoadingActivityIndicatorColor()

    loadingRowStack.addArrangedSubview(loadingIndicator)
    loadingRowStack.addArrangedSubview(loadingMessageLabel)

    addSubview(loadingOverlayHost)
    loadingOverlayHost.addSubview(loadingRowStack)
    NSLayoutConstraint.activate([
      loadingOverlayHost.topAnchor.constraint(equalTo: topAnchor),
      loadingOverlayHost.leadingAnchor.constraint(equalTo: leadingAnchor),
      loadingOverlayHost.trailingAnchor.constraint(equalTo: trailingAnchor),
      loadingOverlayHost.bottomAnchor.constraint(equalTo: bottomAnchor),
      loadingRowStack.centerXAnchor.constraint(equalTo: loadingOverlayHost.centerXAnchor),
      loadingRowStack.centerYAnchor.constraint(equalTo: loadingOverlayHost.centerYAnchor),
    ])
  }

  private func syncLoadingActivityIndicatorColor() {
    loadingIndicator.color = loadingActivityIndicatorColor
  }

  private func applyLoadingChromeForCurrentStyle() {
    switch loadingPresentationStyle {
    case .overlay(let dimmed):
      stackView.isHidden = false
      stackView.alpha = max(0, min(1, dimmed))
      loadingMessageLabel.text = nil
      loadingMessageLabel.isHidden = true
      accessibilityValue = nil
    case .replacesContent(let options):
      stackView.isHidden = true
      stackView.alpha = 1
      loadingRowStack.spacing = max(0, options.spacingAfterIndicator)
      let trimmed = options.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if trimmed.isEmpty {
        loadingMessageLabel.isHidden = true
        loadingMessageLabel.text = nil
        accessibilityValue = nil
      } else {
        loadingMessageLabel.isHidden = false
        loadingMessageLabel.text = options.message
        loadingMessageLabel.font = options.messageFont
        loadingMessageLabel.textColor = options.messageColor
        accessibilityValue = trimmed
      }
    }
  }

  private func hitTestingBounds() -> CGRect {
    let appearanceOutsets = resolveAppearance().interaction.hitTestOutsets
    let imageOutsets = activeImageElements().reduce(UIEdgeInsets.zero) { current, element in
      UIEdgeInsets(
        top: max(current.top, element.hitTestOutsets.top),
        left: max(current.left, element.hitTestOutsets.left),
        bottom: max(current.bottom, element.hitTestOutsets.bottom),
        right: max(current.right, element.hitTestOutsets.right)
      )
    }
    let sum = UIEdgeInsets(
      top: appearanceOutsets.top + imageOutsets.top,
      left: appearanceOutsets.left + imageOutsets.left,
      bottom: appearanceOutsets.bottom + imageOutsets.bottom,
      right: appearanceOutsets.right + imageOutsets.right
    )
    let inset = UIEdgeInsets(
      top: -sum.top + hitTestEdgeInsets.top,
      left: -sum.left + hitTestEdgeInsets.left,
      bottom: -sum.bottom + hitTestEdgeInsets.bottom,
      right: -sum.right + hitTestEdgeInsets.right
    )
    return bounds.inset(by: inset)
  }

  private func disabledVisualMultiplier() -> CGFloat {
    guard !isLoading else { return 1 }
    guard !isEnabled, automaticallyDimsWhenDisabled else { return 1 }
    return max(0, min(1, disabledDimmingAlpha))
  }

  @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    switch sender.state {
    case .began:
      onLongPressBegan?()
      onLongPressRepeatTick?()
      guard onLongPressRepeatTick != nil, longPressRepeatTickInterval > 0 else { break }
      longPressRepeatTimer?.invalidate()
      let timer = Timer(timeInterval: longPressRepeatTickInterval, repeats: true) { [weak self] _ in
        self?.onLongPressRepeatTick?()
      }
      RunLoop.main.add(timer, forMode: .common)
      longPressRepeatTimer = timer
    case .ended, .cancelled, .failed:
      longPressRepeatTimer?.invalidate()
      longPressRepeatTimer = nil
      onLongPressEnded?()
    default:
      break
    }
  }
  
  // MARK: - Private
  
  private func applyAxis() {
    switch axis {
    case .horizontal:
      stackView.axis = .horizontal
    case .vertical:
      stackView.axis = .vertical
    }
    applyContentAlignmentLayout()
  }

  /// Maps inherited `UIControl` alignment into `contentContainerView` constraints and `UIStackView` distribution/alignment.
  private func applyContentAlignmentLayout() {
    guard stackView.superview === contentContainerView else { return }

    NSLayoutConstraint.deactivate(contentAlignmentConstraints)
    contentAlignmentConstraints.removeAll()

    let h = super.contentHorizontalAlignment
    let v = super.contentVerticalAlignment
    let c = contentContainerView

    applyStackViewMetricsForContentAlignment(horizontal: h, vertical: v)

    var next: [NSLayoutConstraint] = []

    switch h {
    case .fill:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    case .leading, .left:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(lessThanOrEqualTo: c.trailingAnchor),
      ]
    case .trailing, .right:
      next += [
        stackView.leadingAnchor.constraint(greaterThanOrEqualTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    case .center:
      next += [
        stackView.centerXAnchor.constraint(equalTo: c.centerXAnchor),
        stackView.leadingAnchor.constraint(greaterThanOrEqualTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(lessThanOrEqualTo: c.trailingAnchor),
      ]
    @unknown default:
      next += [
        stackView.leadingAnchor.constraint(equalTo: c.leadingAnchor),
        stackView.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      ]
    }

    switch v {
    case .fill:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    case .top:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: c.bottomAnchor),
      ]
    case .bottom:
      next += [
        stackView.topAnchor.constraint(greaterThanOrEqualTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    case .center:
      next += [
        stackView.centerYAnchor.constraint(equalTo: c.centerYAnchor),
        stackView.topAnchor.constraint(greaterThanOrEqualTo: c.topAnchor),
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: c.bottomAnchor),
      ]
    @unknown default:
      next += [
        stackView.topAnchor.constraint(equalTo: c.topAnchor),
        stackView.bottomAnchor.constraint(equalTo: c.bottomAnchor),
      ]
    }

    contentAlignmentConstraints = next
    NSLayoutConstraint.activate(next)
    invalidateIntrinsicContentSize()
  }

  private func applyStackViewMetricsForContentAlignment(
    horizontal h: UIControl.ContentHorizontalAlignment,
    vertical v: UIControl.ContentVerticalAlignment
  ) {
    switch axis {
    case .horizontal:
      switch h {
      case .center:
        stackView.distribution = .equalCentering
      default:
        stackView.distribution = .fill
      }
      stackView.alignment = stackCrossAxisAlignmentForHorizontalStack(vertical: v)
    case .vertical:
      switch v {
      case .center:
        stackView.distribution = .equalCentering
      default:
        stackView.distribution = .fill
      }
      stackView.alignment = stackCrossAxisAlignmentForVerticalStack(horizontal: h)
    }
  }

  private func stackCrossAxisAlignmentForHorizontalStack(vertical v: UIControl.ContentVerticalAlignment) -> UIStackView.Alignment {
    switch v {
    case .top:
      return .top
    case .bottom:
      return .bottom
    case .center:
      return .center
    case .fill:
      return .fill
    @unknown default:
      return .center
    }
  }

  private func stackCrossAxisAlignmentForVerticalStack(horizontal h: UIControl.ContentHorizontalAlignment) -> UIStackView.Alignment {
    switch h {
    case .leading, .left:
      return .leading
    case .trailing, .right:
      return .trailing
    case .center:
      return .center
    case .fill:
      return .fill
    @unknown default:
      return .center
    }
  }

  private func requestVisualRefresh(rebuildContentLayout: Bool = false) {
    if rebuildContentLayout {
      needsContentLayoutRefresh = true
    }
    if batchUpdateDepth > 0 {
      needsVisualRefresh = true
      return
    }
    flushPendingRefresh()
  }

  private func flushPendingRefresh() {
    if needsContentLayoutRefresh {
      applyContentLayout()
      needsContentLayoutRefresh = false
    }
    applyTextForCurrentState()
    applyImagesForCurrentState()
    applyCustomContentForCurrentState()
    applyAppearanceForCurrentState()
  }
  
  // MARK: - Title & Subtitle lifecycle (lazy creation / timely cleanup)

  private func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  private func titleLabelIfNeeded() -> UILabel {
    if let existing = titleLabel { return existing }
    let label = makeTitleLabel()
    titleLabel = label
    return label
  }

  private func releaseTitleLabel() {
    guard let label = titleLabel else { return }
    // Clear the subtitle first to avoid leaving behind internal constraints.
    releaseSubtitleLabel()
    titleContainerView?.removeFromSuperview()
    titleContainerView = nil
    titleLabelTopConstraint = nil
    titleLabelLeadingConstraint = nil
    titleLabelTrailingConstraint = nil
    titleLabelBottomConstraintToContainer = nil
    subtitleTopConstraint = nil
    subtitleLeadingConstraint = nil
    subtitleTrailingConstraint = nil
    subtitleBottomConstraint = nil
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    titleLabel = nil
  }
  
  private func titleContainerViewIfNeeded() -> UIView {
    if let existing = titleContainerView { return existing }
    let container = UIView()
    container.isUserInteractionEnabled = false
    container.backgroundColor = .clear
    titleContainerView = container
    
    let label = titleLabelIfNeeded()
    if label.superview !== container {
      container.addSubview(label)
    }
    label.translatesAutoresizingMaskIntoConstraints = false

    let top = label.topAnchor.constraint(equalTo: container.topAnchor)
    let leading = label.leadingAnchor.constraint(equalTo: container.leadingAnchor)
    let trailing = label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    titleLabelTopConstraint = top
    titleLabelLeadingConstraint = leading
    titleLabelTrailingConstraint = trailing
    titleLabelBottomConstraintToContainer = bottom
    NSLayoutConstraint.activate([top, leading, trailing, bottom])
    return container
  }
  
  private func makeImageView() -> UIImageView {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFit
    imgView.setContentHuggingPriority(.required, for: .vertical)
    imgView.setContentHuggingPriority(.required, for: .horizontal)
    return imgView
  }

  private func makeSubtitleLabel() -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  private func subtitleLabelIfNeeded() -> UILabel {
    if let existing = subtitleLabel { return existing }
    let label = makeSubtitleLabel()
    subtitleLabel = label
    
    let container = titleContainerViewIfNeeded()
    if label.superview !== container {
      container.addSubview(label)
    }
    label.translatesAutoresizingMaskIntoConstraints = false
    
    // When the subtitle is added, the title's bottom is no longer pinned directly to the container;
    // it is connected through the subtitle.
    titleLabelBottomConstraintToContainer?.isActive = false
    
    let leading = label.leadingAnchor.constraint(equalTo: container.leadingAnchor)
    let trailing = label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    let top = label.topAnchor.constraint(equalTo: titleLabelIfNeeded().bottomAnchor)
    let bottom = label.bottomAnchor.constraint(equalTo: container.bottomAnchor)

    subtitleTopConstraint = top
    subtitleLeadingConstraint = leading
    subtitleTrailingConstraint = trailing
    subtitleBottomConstraint = bottom

    NSLayoutConstraint.activate([top, leading, trailing, bottom])
    return label
  }

  private func releaseSubtitleLabel() {
    guard let label = subtitleLabel else { return }
    subtitleTopConstraint?.isActive = false
    subtitleLeadingConstraint?.isActive = false
    subtitleTrailingConstraint?.isActive = false
    subtitleBottomConstraint?.isActive = false
    subtitleTopConstraint = nil
    subtitleLeadingConstraint = nil
    subtitleTrailingConstraint = nil
    subtitleBottomConstraint = nil
    
    label.removeFromSuperview()
    label.text = nil
    label.attributedText = nil
    subtitleLabel = nil
    
    // After the subtitle is released, re-enable the title as the container's bottom anchor.
    titleLabelBottomConstraintToContainer?.isActive = true
  }

  /// Update constraints inside the title container based on the resolved `LabelAttributes.contentInsets`,
  /// including spacing between title and subtitle (`title.bottom + subtitle.top`).
  private func updateTitleContainerLayoutConstraints() {
    guard let container = titleContainerView,
          let titleL = titleLabel,
          titleL.superview === container
    else { return }

    let titleText = resolveTitleElement()
    let ti = titleText.contentInsets
    titleLabelTopConstraint?.constant = ti.top
    titleLabelLeadingConstraint?.constant = ti.leading
    titleLabelTrailingConstraint?.constant = -ti.trailing

    if let subtitleL = subtitleLabel,
       subtitleL.superview === container,
       let subText = resolveSubtitleElement(),
       subtitleHasRenderableContent(subText) {
      let si = subText.contentInsets
      titleLabelBottomConstraintToContainer?.isActive = false
      subtitleTopConstraint?.constant = ti.bottom + si.top
      subtitleLeadingConstraint?.constant = si.leading
      subtitleTrailingConstraint?.constant = -si.trailing
      subtitleBottomConstraint?.constant = -si.bottom
    } else {
      titleLabelBottomConstraintToContainer?.isActive = true
      titleLabelBottomConstraintToContainer?.constant = -ti.bottom
    }

    invalidateIntrinsicContentSize()
  }

  private func imageViewIfNeeded(for slot: ImageSlot) -> UIImageView {
    switch slot {
    case .center:
      if let existing = imageView { return existing }
      let v = makeImageView()
      imageView = v
      return v
    case .leading:
      if let existing = leadingImageView { return existing }
      let v = makeImageView()
      leadingImageView = v
      return v
    case .trailing:
      if let existing = trailingImageView { return existing }
      let v = makeImageView()
      trailingImageView = v
      return v
    }
  }

  private func clearImageSlot(_ slot: ImageSlot) {
    let view: UIImageView?
    switch slot {
    case .center: view = imageView
    case .leading: view = leadingImageView
    case .trailing: view = trailingImageView
    }
    guard let imageView = view else { return }
    applyImage(nil, to: imageView)
    imageView.removeFromSuperview()
    switch slot {
    case .center: self.imageView = nil
    case .leading: leadingImageView = nil
    case .trailing: trailingImageView = nil
    }
  }

  private func releaseAllImageSlots() {
    clearImageSlot(.center)
    clearImageSlot(.leading)
    clearImageSlot(.trailing)
  }

  private func customContentHostIfNeeded() -> FKButtonCustomContentHostView {
    if let existing = customContentHost { return existing }
    let host = FKButtonCustomContentHostView()
    host.isUserInteractionEnabled = false
    host.backgroundColor = .clear
    customContentHost = host
    return host
  }

  private func releaseCustomContentHost() {
    embeddedCustomContentView?.removeFromSuperview()
    embeddedCustomContentView = nil
    customContentHost?.subviews.forEach { $0.removeFromSuperview() }
    customContentHost?.removeFromSuperview()
    customContentHost = nil
  }
  
  private func applyContentLayout() {
    stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    
    switch content.kind {
    case .textOnly:
      stackView.spacing = 0
      stackView.addArrangedSubview(titleContainerViewIfNeeded())
    case .imageOnly:
      stackView.spacing = 0
      stackView.addArrangedSubview(imageViewIfNeeded(for: .center))
    case .textAndImage(let alignment):
      switch alignment {
      case .leading:
        stackView.addArrangedSubview(imageViewIfNeeded(for: .leading))
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
      case .trailing:
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
        stackView.addArrangedSubview(imageViewIfNeeded(for: .trailing))
      case .bothSides:
        stackView.addArrangedSubview(imageViewIfNeeded(for: .leading))
        stackView.addArrangedSubview(titleContainerViewIfNeeded())
        stackView.addArrangedSubview(imageViewIfNeeded(for: .trailing))
      }
    case .custom:
      stackView.addArrangedSubview(customContentHostIfNeeded())
    }
  }
  
  private func applyAppearanceForCurrentState() {
    let appearance = resolveAppearance()

    if isLoading {
      alpha = 1
      transform = .identity
    } else {
      let feedback = appearance.interaction.isHighlightFeedbackEnabled
      alpha = resolvedAlpha(for: appearance) * disabledVisualMultiplier()
      transform = (isHighlighted && feedback)
        ? CGAffineTransform(scaleX: appearance.interaction.pressedScale, y: appearance.interaction.pressedScale)
        : .identity
    }

    if let gradient = appearance.backgroundGradient {
      backgroundGradientLayer.isHidden = false
      backgroundGradientLayer.colors = gradient.colors.map(\.cgColor)
      if let locations = gradient.locations {
        backgroundGradientLayer.locations = locations.map { NSNumber(value: Double($0)) }
      } else {
        backgroundGradientLayer.locations = nil
      }
      backgroundGradientLayer.startPoint = gradient.startPoint
      backgroundGradientLayer.endPoint = gradient.endPoint
      backgroundColor = .clear
    } else {
      backgroundGradientLayer.isHidden = true
      backgroundColor = appearance.backgroundColor
    }
    layer.borderWidth = appearance.border.width
    layer.borderColor = appearance.border.color.cgColor
    layer.cornerCurve = appearance.cornerStyle.curve
    layer.maskedCorners = appearance.cornerStyle.maskedCorners
    applyCornerMetrics(using: appearance)
    
    if let shadow = appearance.shadow {
      layer.shadowOffset = shadow.offset
      layer.shadowRadius = shadow.radius
      layer.shadowOpacity = shadow.opacity
      layer.shadowColor = shadow.color.cgColor
      layer.masksToBounds = false
      updateShadowPath(using: appearance)
    } else {
      layer.shadowOpacity = 0
      layer.shadowPath = nil
      layer.masksToBounds = true
    }
    
    let insets = appearance.contentInsets
    topConstraint?.constant = insets.top
    leadingConstraint?.constant = insets.leading
    trailingConstraint?.constant = -insets.trailing
    bottomConstraint?.constant = -insets.bottom
    
    invalidateIntrinsicContentSize()
  }
  
  private func applyCornerMetrics(using appearance: Appearance) {
    switch appearance.cornerStyle.corner {
    case .none:
      layer.cornerRadius = 0
    case let .fixed(radius):
      layer.cornerRadius = radius
    case .capsule:
      layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }

    if let clipsToBounds = appearance.clipsToBounds {
      self.clipsToBounds = clipsToBounds
    } else {
      self.clipsToBounds = (appearance.shadow == nil)
    }
  }

  /// Rebuilds `layer.shadowPath` from current bounds and corner settings when enabled.
  private func updateShadowPath(using appearance: Appearance) {
    guard appearance.shadow != nil, appearance.shadowPathStrategy == .automatic else {
      layer.shadowPath = nil
      return
    }
    layer.shadowPath = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: appearance.cornerStyle.maskedCorners.uiRectCorner,
      cornerRadii: CGSize(width: layer.cornerRadius, height: layer.cornerRadius)
    ).cgPath
  }

  private func resolvedAlpha(for appearance: Appearance) -> CGFloat {
    let base = appearance.alpha
    let highlight = isHighlighted && isEnabled && appearance.interaction.isHighlightFeedbackEnabled
    if highlight {
      return base * appearance.interaction.pressedAlpha
    }
    return base
  }

  private func activeImageElements() -> [ImageAttributes] {
    switch content.kind {
    case .imageOnly:
      return [resolveImageElement(for: .center)].compactMap { $0 }
    case let .textAndImage(alignment):
      switch alignment {
      case .leading:
        return [resolveImageElement(for: .leading)].compactMap { $0 }
      case .trailing:
        return [resolveImageElement(for: .trailing)].compactMap { $0 }
      case .bothSides:
        return [resolveImageElement(for: .leading), resolveImageElement(for: .trailing)].compactMap { $0 }
      }
    case .textOnly, .custom:
      return []
    }
  }
  
  private func applyTextForCurrentState() {
    switch content.kind {
    case .textOnly, .textAndImage:
      let title = resolveTitleElement()
      applyTitle(title)
      applySubtitleForCurrentState()
      updateTitleContainerLayoutConstraints()
    case .imageOnly:
      releaseTitleLabel()
      releaseSubtitleLabel()
      let image = resolveImageElement(for: .center)
      accessibilityLabel = image?.accessibilityLabel
      accessibilityHint = image?.accessibilityHint
    case .custom:
      releaseTitleLabel()
      releaseSubtitleLabel()
      let customView = resolveCustomContent()?.view
      accessibilityLabel = customView?.accessibilityLabel
      accessibilityHint = customView?.accessibilityHint
    }
  }

  // MARK: - Subviews rendering

  private func resolveSubtitleElement() -> LabelAttributes? {
    resolveFromStateMap(subtitleByState)
  }

  private func subtitleHasRenderableContent(_ subtitle: LabelAttributes) -> Bool {
    if subtitle.attributedText != nil { return true }
    if let text = subtitle.text { return !text.isEmpty }
    return false
  }

  private func applySubtitleForCurrentState() {
    guard let subtitle = resolveSubtitleElement(), subtitleHasRenderableContent(subtitle) else {
      releaseSubtitleLabel()
      return
    }
    applySubtitle(subtitle)
  }
  
  private func applyImagesForCurrentState() {
    switch content.kind {
    case .imageOnly:
      clearImageSlot(.leading)
      clearImageSlot(.trailing)
      applyImage(resolveImageElement(for: .center), to: imageViewIfNeeded(for: .center))
      stackView.spacing = 0
    case let .textAndImage(alignment):
      switch alignment {
      case .leading:
        clearImageSlot(.center)
        let leading = resolveImageElement(for: .leading)
        applyImage(leading, to: imageViewIfNeeded(for: .leading))
        clearImageSlot(.trailing)
        stackView.spacing = leading?.spacingToTitle ?? 0
      case .trailing:
        clearImageSlot(.center)
        clearImageSlot(.leading)
        let trailing = resolveImageElement(for: .trailing)
        applyImage(trailing, to: imageViewIfNeeded(for: .trailing))
        stackView.spacing = trailing?.spacingToTitle ?? 0
      case .bothSides:
        clearImageSlot(.center)
        let leading = resolveImageElement(for: .leading)
        let trailing = resolveImageElement(for: .trailing)
        applyImage(leading, to: imageViewIfNeeded(for: .leading))
        applyImage(trailing, to: imageViewIfNeeded(for: .trailing))
        stackView.spacing = max(leading?.spacingToTitle ?? 0, trailing?.spacingToTitle ?? 0)
      }
    case .textOnly:
      releaseAllImageSlots()
      stackView.spacing = 0
    case .custom:
      releaseAllImageSlots()
      stackView.spacing = 0
    }
  }

  private func resolveCustomContent() -> CustomContent? {
    resolveFromStateMap(customContentByState)
  }

  private func applyCustomContentForCurrentState() {
    guard case .custom = content.kind else {
      releaseCustomContentHost()
      return
    }

    let element = resolveCustomContent()
    let newView = element?.view

    // Only a single "pure custom" content slot for now.
    // `spacingToAdjacentContent` is reserved for future mixed text/image layouts.
    stackView.spacing = element?.spacingToAdjacentContent ?? 0

    let host = customContentHostIfNeeded()

    if embeddedCustomContentView !== newView {
      embeddedCustomContentView?.removeFromSuperview()
      embeddedCustomContentView = nil

      if let view = newView {
        host.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          view.topAnchor.constraint(equalTo: host.topAnchor),
          view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
          view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
          view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        embeddedCustomContentView = view
      }
    }

    host.invalidateIntrinsicContentSize()
    host.isHidden = (newView == nil)
    invalidateIntrinsicContentSize()
  }

  private var stateResolutionOrder: [UIControl.State] {
    if let provider = stateResolutionProvider {
      return provider(isEnabled, isSelected, isHighlighted)
    }
    if !isEnabled { return [.disabled, .normal] }
    if isSelected { return [.selected, .normal] }
    if isHighlighted { return [.highlighted, .normal] }
    return [.normal]
  }

  private func resolveFromStateMap<T>(_ map: StatefulValues<T>) -> T? {
    for state in stateResolutionOrder {
      if let value = map[state.rawValue] {
        return value
      }
    }
    return nil
  }

  private func resolveAppearance() -> Appearance {
    resolveFromStateMap(appearanceByState) ?? .default
  }

  private func resolveTitleElement() -> LabelAttributes {
    resolveFromStateMap(titleByState) ?? .default
  }

  private func resolveImageElement(for slot: ImageSlot) -> ImageAttributes? {
    guard let map = imagesBySlotAndState[slot] else { return nil }
    return resolveFromStateMap(map)
  }

  private func setImage(_ image: ImageAttributes?, for state: UIControl.State, slot: ImageSlot) {
    if var map = imagesBySlotAndState[slot] {
      if let image {
        map[state.rawValue] = image
      } else {
        map.removeValue(forKey: state.rawValue)
      }
      imagesBySlotAndState[slot] = map
    } else {
      imagesBySlotAndState[slot] = image.map { [state.rawValue: $0] } ?? [:]
    }
  }

  private func applyTitle(_ title: LabelAttributes) {
    let label = titleLabelIfNeeded()
    label.textAlignment = title.alignment
    label.numberOfLines = title.numberOfLines
    label.lineBreakMode = title.lineBreakMode
    label.adjustsFontSizeToFitWidth = title.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = title.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = title.allowsDefaultTighteningForTruncation
    label.shadowColor = title.shadowColor
    label.shadowOffset = title.shadowOffset

    if let accessibilityLabel = title.accessibilityLabel {
      self.accessibilityLabel = accessibilityLabel
    }
    accessibilityHint = title.accessibilityHint

    if let attributed = title.attributedText {
      label.attributedText = attributed
      if self.accessibilityLabel == nil {
        self.accessibilityLabel = attributed.string
      }
      return
    }

    let text = transformedText(from: title.text ?? "", by: title.textTransform)

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = title.alignment
    paragraph.lineBreakMode = title.lineBreakMode
    if title.lineSpacing > 0 {
      paragraph.lineSpacing = title.lineSpacing
    }
    if title.lineHeight > 0 {
      paragraph.minimumLineHeight = title.lineHeight
      paragraph.maximumLineHeight = title.lineHeight
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: title.font,
      .foregroundColor: title.color,
      .kern: title.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
    if self.accessibilityLabel == nil {
      self.accessibilityLabel = text
    }
  }

  private func applySubtitle(_ subtitle: LabelAttributes) {
    let label = subtitleLabelIfNeeded()
    label.textAlignment = subtitle.alignment
    label.numberOfLines = subtitle.numberOfLines
    label.lineBreakMode = subtitle.lineBreakMode
    label.adjustsFontSizeToFitWidth = subtitle.adjustsFontSizeToFitWidth
    label.minimumScaleFactor = subtitle.minimumScaleFactor
    label.allowsDefaultTighteningForTruncation = subtitle.allowsDefaultTighteningForTruncation
    label.shadowColor = subtitle.shadowColor
    label.shadowOffset = subtitle.shadowOffset

    if let attributed = subtitle.attributedText {
      label.attributedText = attributed
      return
    }

    let text = transformedText(from: subtitle.text ?? "", by: subtitle.textTransform)

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = subtitle.alignment
    paragraph.lineBreakMode = subtitle.lineBreakMode
    if subtitle.lineSpacing > 0 {
      paragraph.lineSpacing = subtitle.lineSpacing
    }
    if subtitle.lineHeight > 0 {
      paragraph.minimumLineHeight = subtitle.lineHeight
      paragraph.maximumLineHeight = subtitle.lineHeight
    }

    let attributes: [NSAttributedString.Key: Any] = [
      .font: subtitle.font,
      .foregroundColor: subtitle.color,
      .kern: subtitle.kerning,
      .paragraphStyle: paragraph,
    ]
    label.attributedText = NSAttributedString(string: text, attributes: attributes)
  }

  private func applyImage(_ element: ImageAttributes?, to imageView: UIImageView) {
    guard let element else {
      imageView.image = nil
      imageView.alpha = 0
      deactivateImageConstraints(for: imageView)
      return
    }

    let image: UIImage? = {
      if let image = element.image {
        return image
      }
      guard let systemName = element.systemName else { return nil }
      if let symbolConfiguration = element.symbolConfiguration {
        return UIImage(systemName: systemName, withConfiguration: symbolConfiguration)
      }
      return UIImage(systemName: systemName)
    }()

    var rendered = image?.withRenderingMode(element.renderingMode)
    if let symbolConfiguration = element.symbolConfiguration {
      rendered = rendered?.applyingSymbolConfiguration(symbolConfiguration)
    }
    rendered = rendered.flatMap { paddedImage(from: $0, contentInsets: element.contentInsets) }

    imageView.image = rendered
    imageView.tintColor = element.tintColor
    imageView.contentMode = resolvedImageContentMode(for: element)
    imageView.semanticContentAttribute = element.flipsForRightToLeftLayoutDirection ? .unspecified : .forceLeftToRight
    imageView.accessibilityLabel = element.accessibilityLabel
    imageView.accessibilityHint = element.accessibilityHint
    imageView.accessibilityIdentifier = element.accessibilityIdentifier
    imageView.isAccessibilityElement = false
    imageView.isHidden = (rendered == nil)
    imageView.alpha = (rendered == nil) ? 0 : element.alpha

    deactivateImageConstraints(for: imageView)
    var constraints: [NSLayoutConstraint] = []
    imageView.translatesAutoresizingMaskIntoConstraints = false

    if let fixedSize = element.fixedSize {
      constraints.append(imageView.widthAnchor.constraint(equalToConstant: fixedSize.width))
      constraints.append(imageView.heightAnchor.constraint(equalToConstant: fixedSize.height))
    } else {
      if let minimum = element.minimumSize {
        constraints.append(imageView.widthAnchor.constraint(greaterThanOrEqualToConstant: minimum.width))
        constraints.append(imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: minimum.height))
      }
      if let maximum = element.maximumSize {
        constraints.append(imageView.widthAnchor.constraint(lessThanOrEqualToConstant: maximum.width))
        constraints.append(imageView.heightAnchor.constraint(lessThanOrEqualToConstant: maximum.height))
      }
    }

    NSLayoutConstraint.activate(constraints)
    imageConstraints[ObjectIdentifier(imageView)] = constraints
  }

  private func deactivateImageConstraints(for imageView: UIImageView) {
    let key = ObjectIdentifier(imageView)
    if let constraints = imageConstraints[key] {
      NSLayoutConstraint.deactivate(constraints)
      imageConstraints[key] = nil
    }
  }

  private func transformedText(from text: String, by transform: LabelAttributes.TextTransform) -> String {
    switch transform {
    case .none:
      return text
    case .uppercase:
      return text.uppercased()
    case .lowercase:
      return text.lowercased()
    }
  }

  /// Enforces aspect-preserving content mode when requested by `ImageAttributes.preserveAspectRatio`.
  private func resolvedImageContentMode(for element: ImageAttributes) -> UIView.ContentMode {
    guard element.preserveAspectRatio else { return element.contentMode }
    switch element.contentMode {
    case .scaleToFill:
      return .scaleAspectFit
    default:
      return element.contentMode
    }
  }

  /// Applies directional insets by rendering into a padded bitmap.
  private func paddedImage(from image: UIImage, contentInsets: NSDirectionalEdgeInsets) -> UIImage {
    guard contentInsets != .zero else { return image }
    let directional = effectiveDirectionalInsets(contentInsets)
    let cacheKey = "\(ObjectIdentifier(image).hashValue)-\(directional.top)-\(directional.left)-\(directional.bottom)-\(directional.right)-\(image.scale)" as NSString
    if let cached = Self.paddedImageCache.object(forKey: cacheKey) {
      return cached
    }
    let horizontal = directional.left + directional.right
    let vertical = directional.top + directional.bottom
    let size = CGSize(width: image.size.width + horizontal, height: image.size.height + vertical)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let padded = renderer.image { _ in
      image.draw(at: CGPoint(x: directional.left, y: directional.top))
    }
    Self.paddedImageCache.setObject(padded, forKey: cacheKey)
    return padded
  }

  /// Resolves directional insets into physical edges under current layout direction.
  private func effectiveDirectionalInsets(_ insets: NSDirectionalEdgeInsets) -> UIEdgeInsets {
    let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
    return UIEdgeInsets(
      top: max(0, insets.top),
      left: max(0, isRTL ? insets.trailing : insets.leading),
      bottom: max(0, insets.bottom),
      right: max(0, isRTL ? insets.leading : insets.trailing)
    )
  }
}

private extension CACornerMask {
  var uiRectCorner: UIRectCorner {
    var corners: UIRectCorner = []
    if contains(.layerMinXMinYCorner) { corners.insert(.topLeft) }
    if contains(.layerMaxXMinYCorner) { corners.insert(.topRight) }
    if contains(.layerMinXMaxYCorner) { corners.insert(.bottomLeft) }
    if contains(.layerMaxXMaxYCorner) { corners.insert(.bottomRight) }
    return corners
  }
}

// MARK: - Custom content sizing

/// Custom content host: a single subview pinned to fill, reporting fitting/intrinsic size to `UIStackView`.
private final class FKButtonCustomContentHostView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    isOpaque = false
  }

  override func didAddSubview(_ subview: UIView) {
    super.didAddSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override func willRemoveSubview(_ subview: UIView) {
    super.willRemoveSubview(subview)
    invalidateIntrinsicContentSize()
  }

  override var intrinsicContentSize: CGSize {
    guard let subview = subviews.first else {
      return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    let fitted = subview.systemLayoutSizeFitting(
      CGSize(width: UIView.layoutFittingCompressedSize.width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .fittingSizeLevel,
      verticalFittingPriority: .fittingSizeLevel
    )
    if fitted.width > 0.5, fitted.height > 0.5 {
      return fitted
    }
    let intrinsic = subview.intrinsicContentSize
    let width = intrinsic.width > 0 ? intrinsic.width : UIView.noIntrinsicMetric
    let height = intrinsic.height > 0 ? intrinsic.height : UIView.noIntrinsicMetric
    if width != UIView.noIntrinsicMetric || height != UIView.noIntrinsicMetric {
      return CGSize(width: width, height: height)
    }
    return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
  }
}
