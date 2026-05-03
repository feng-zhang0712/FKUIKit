import UIKit

/// A highly configurable determinate / indeterminate progress indicator (linear or ring) with optional buffer, labels, accessibility, and optional **button** interaction.
///
/// Assign ``configuration`` to change appearance. Use ``setProgress(_:animated:)`` and ``setBufferProgress(_:animated:)`` for animated updates.
/// Set ``isIndeterminate`` to `true` and choose ``FKProgressBarMotionConfiguration/indeterminateStyle`` for indeterminate modes.
///
/// When ``FKProgressBarInteractionConfiguration/interactionMode`` is ``FKProgressBarInteractionMode/button``, use ``UIControl/addTarget(_:action:for:)`` with ``UIControl/Event/touchUpInside`` or ``UIControl/Event/primaryActionTriggered`` (e.g. start a download, then update progress).
///
/// Global defaults: set ``defaultConfiguration`` at launch or use ``FKProgressBarDefaults/configuration``.
@IBDesignable
@MainActor
public final class FKProgressBar: UIControl {
  /// Baseline copied by `init(frame:)` until you replace ``configuration``.
  public static var defaultConfiguration: FKProgressBarConfiguration {
    get { FKProgressBarDefaults.configuration }
    set { FKProgressBarDefaults.configuration = newValue }
  }

  /// Style and behavior; assigning invalidates layout and refreshes dynamic colors on the next layout pass.
  public var configuration: FKProgressBarConfiguration = FKProgressBar.defaultConfiguration {
    didSet {
      applyConfigurationToLabel()
      applyInteractionModeFromConfiguration()
      refreshTouchHapticWiring()
      updateTouchAppearance()
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      updateAccessibility()
    }
  }

  /// Normalized primary progress in `0...1`.
  public private(set) var progress: CGFloat = 0

  /// Normalized buffer progress in `0...1` (shown when ``FKProgressBarAppearanceConfiguration/showsBuffer`` is `true`).
  public private(set) var bufferProgress: CGFloat = 0

  /// When `true`, determinate fills are de-emphasized and ``FKProgressBarMotionConfiguration/indeterminateStyle`` drives motion (when ``FKProgressBarMotionConfiguration/playsIndeterminateAnimation`` is `true`).
  public var isIndeterminate: Bool = false {
    didSet {
      guard isIndeterminate != oldValue else { return }
      updateLabelText()
      updateAccessibility()
      delegate?.progressBar(self, didChangeIndeterminate: isIndeterminate)
      setNeedsLayout()
    }
  }

  public weak var delegate: FKProgressBarDelegate?

  private let layerStack = FKProgressBarLayerStack()
  private let valueLabel = UILabel()
  private var animateNextLayout = false

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a bar with an explicit configuration.
  public convenience init(configuration: FKProgressBarConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits.insert(.updatesFrequently)
    backgroundColor = .clear
    clipsToBounds = false
    layerStack.install()
    layer.insertSublayer(layerStack.container, at: 0)
    valueLabel.textAlignment = .center
    valueLabel.numberOfLines = 1
    valueLabel.lineBreakMode = .byTruncatingTail
    valueLabel.isAccessibilityElement = false
    valueLabel.isUserInteractionEnabled = false
    addSubview(valueLabel)
    applyConfigurationToLabel()
    applyInteractionModeFromConfiguration()
    refreshTouchHapticWiring()
    updateTouchAppearance()
    updateAccessibility()
  }

  // MARK: - Public API

  /// Sets normalized progress; values are clamped to `0...1`.
  public func setProgress(_ value: CGFloat, animated: Bool) {
    let clamped = min(max(value, 0), 1)
    let from = progress
    progress = clamped
    let duration = resolvedAnimationDuration(animated: animated)
    if animated, duration > 0 {
      delegate?.progressBar(self, willAnimateProgress: from, to: clamped, duration: duration)
    }
    animateNextLayout = animated
    fireCompletionHapticIfNeeded(from: from, to: clamped)
    setNeedsLayout()
    layoutIfNeeded()
    delegate?.progressBar(self, didAnimateProgressTo: clamped)
    updateLabelText()
    updateAccessibility()
  }

  /// Sets normalized buffer progress; clamped to `0...1`.
  public func setBufferProgress(_ value: CGFloat, animated: Bool) {
    bufferProgress = min(max(value, 0), 1)
    animateNextLayout = animateNextLayout || animated
    delegate?.progressBar(self, didUpdateBufferProgress: bufferProgress)
    setNeedsLayout()
    updateAccessibility()
  }

  /// Convenience: sets both primary and buffer in one layout pass.
  public func setProgress(_ progress: CGFloat, buffer: CGFloat, animated: Bool) {
    let p = min(max(progress, 0), 1)
    let b = min(max(buffer, 0), 1)
    let from = self.progress
    self.progress = p
    self.bufferProgress = b
    let duration = resolvedAnimationDuration(animated: animated)
    if animated, duration > 0 {
      delegate?.progressBar(self, willAnimateProgress: from, to: p, duration: duration)
    }
    animateNextLayout = animated
    fireCompletionHapticIfNeeded(from: from, to: p)
    setNeedsLayout()
    layoutIfNeeded()
    delegate?.progressBar(self, didUpdateBufferProgress: b)
    delegate?.progressBar(self, didAnimateProgressTo: p)
    updateLabelText()
    updateAccessibility()
  }

  /// Begins indeterminate presentation according to ``FKProgressBarMotionConfiguration/indeterminateStyle`` (animations honor ``FKProgressBarMotionConfiguration/playsIndeterminateAnimation``).
  public func startIndeterminate() {
    isIndeterminate = true
  }

  /// Stops indeterminate presentation and restores determinate fills.
  public func stopIndeterminate() {
    isIndeterminate = false
    layerStack.animator.stopAll()
    setNeedsLayout()
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    let reduced = UIAccessibility.isReduceMotionEnabled
    let animated = animateNextLayout
    animateNextLayout = false
    layerStack.layout(
      in: bounds,
      configuration: configuration,
      progress: progress,
      buffer: bufferProgress,
      isIndeterminate: isIndeterminate,
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      traitCollection: traitCollection,
      reducedMotion: reduced,
      animated: animated,
      animationDuration: configuration.motion.animationDuration,
      timing: configuration.motion.timing,
      prefersSpring: configuration.motion.prefersSpringAnimation,
      springDamping: configuration.motion.springDampingRatio,
      springVelocity: configuration.motion.springVelocity
    )
    layoutValueLabel()
    updateTouchAppearance()
  }

  public override var intrinsicContentSize: CGSize {
    let c = configuration
    let insets = c.layout.contentInsets
    let labelBlock = labelIntrinsicAxisContribution()

    switch c.layout.variant {
    case .linear:
      switch c.layout.axis {
      case .horizontal:
        let h = insets.top + insets.bottom + c.layout.trackThickness + labelBlock.vertical
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
      case .vertical:
        let w = insets.left + insets.right + c.layout.trackThickness + labelBlock.horizontal
        return CGSize(width: w, height: UIView.noIntrinsicMetric)
      }
    case .ring:
      let d = (c.layout.ringDiameter ?? 36) + labelBlock.bothAxes
      return CGSize(width: d + insets.left + insets.right, height: d + insets.top + insets.bottom)
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsLayout()
  }

  public override var isEnabled: Bool {
    didSet {
      if configuration.interaction.interactionMode == .button {
        isUserInteractionEnabled = isEnabled
      }
      updateTouchAppearance()
      updateAccessibility()
    }
  }

  public override var isHighlighted: Bool {
    didSet {
      guard configuration.interaction.interactionMode == .button else { return }
      updateTouchAppearance()
    }
  }

  public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    guard configuration.interaction.interactionMode == .button else { return false }
    let ok = super.beginTracking(touch, with: event)
    if ok {
      delegate?.progressBarDidBeginTracking(self)
    }
    return ok
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    let wasTracking = isTracking
    super.endTracking(touch, with: event)
    guard configuration.interaction.interactionMode == .button, wasTracking else { return }
    let cancelled = touch.map { !bounds.contains($0.location(in: self)) } ?? true
    delegate?.progressBarDidEndTracking(self, cancelled: cancelled)
  }

  public override func cancelTracking(with event: UIEvent?) {
    let wasTracking = isTracking
    super.cancelTracking(with: event)
    guard configuration.interaction.interactionMode == .button, wasTracking else { return }
    delegate?.progressBarDidEndTracking(self, cancelled: true)
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard configuration.interaction.interactionMode == .button,
          let minSize = configuration.interaction.minimumTouchTargetSize,
          minSize.width > 0, minSize.height > 0
    else {
      return super.point(inside: point, with: event)
    }
    let w = max(bounds.width, minSize.width)
    let h = max(bounds.height, minSize.height)
    let hit = CGRect(x: bounds.midX - w / 2, y: bounds.midY - h / 2, width: w, height: h)
    return hit.contains(point)
  }

  // MARK: - Private

  private func resolvedAnimationDuration(animated: Bool) -> TimeInterval {
    guard animated else { return 0 }
    if configuration.motion.respectsReducedMotion, UIAccessibility.isReduceMotionEnabled { return 0 }
    return configuration.motion.animationDuration
  }

  private func fireCompletionHapticIfNeeded(from: CGFloat, to: CGFloat) {
    guard from < 1, to >= 1 else { return }
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    switch configuration.motion.completionHaptic {
    case .none:
      return
    case .light:
      style = .light
    case .medium:
      style = .medium
    case .rigid:
      style = .rigid
    }
    let gen = UIImpactFeedbackGenerator(style: style)
    gen.prepare()
    gen.impactOccurred()
  }

  private func applyConfigurationToLabel() {
    valueLabel.font = configuration.label.font
    valueLabel.textColor = configuration.label.usesSemanticTextColor ? .label : configuration.label.textColor
    valueLabel.isHidden = configuration.label.placement == .none
    switch configuration.label.contentMode {
    case .customTitleWithProgressSubtitle:
      valueLabel.numberOfLines = 2
    case .customTitleOnly:
      valueLabel.numberOfLines = 0
    default:
      valueLabel.numberOfLines = 1
    }
    updateLabelText()
  }

  private func updateLabelText() {
    guard configuration.label.placement != .none else {
      valueLabel.text = nil
      return
    }
    let c = configuration
    let formatted = FKProgressBarLabelFormatting.displayString(progress: progress, configuration: c)
    switch c.label.contentMode {
    case .formattedProgress:
      valueLabel.text = formatted
    case .customTitleOnly:
      valueLabel.text = c.label.customTitle
    case .customTitleWhenIdle:
      let idle = !isIndeterminate && progress < 0.000_001
      if idle {
        valueLabel.text = c.label.customTitle
      } else if isIndeterminate, !c.label.customTitle.isEmpty {
        valueLabel.text = c.label.customTitle
      } else {
        valueLabel.text = formatted
      }
    case .customTitleWithProgressSubtitle:
      if c.label.customTitle.isEmpty {
        valueLabel.text = formatted
      } else {
        valueLabel.text = "\(c.label.customTitle)\n\(formatted)"
      }
    }
  }

  private func layoutValueLabel() {
    guard configuration.label.placement != .none else {
      valueLabel.frame = .zero
      return
    }
    let pad = configuration.label.padding
    let c = configuration
    let track = FKProgressBarLayoutEngine.trackRect(in: bounds, contentInsets: c.layout.contentInsets)
    let maxLabelWidth = max(0, bounds.width - pad * 2)
    valueLabel.preferredMaxLayoutWidth = maxLabelWidth

    let text = valueLabel.text ?? ""
    let font = valueLabel.font ?? UIFont.preferredFont(forTextStyle: .footnote)
    let attrs: [NSAttributedString.Key: Any] = [.font: font]

    let usesFullHorizontalWidth: Bool
    switch c.label.placement {
    case .above, .below, .centeredOnTrack:
      usesFullHorizontalWidth = true
    case .none, .leading, .trailing:
      usesFullHorizontalWidth = false
    }

    let labelWidth: CGFloat
    if usesFullHorizontalWidth {
      // Give the label the full usable width so short strings like "100%" are not ellipsized; long text wraps within `numberOfLines`.
      labelWidth = maxLabelWidth
    } else {
      let singleLineW = text.isEmpty ? 0 : ceil(
        (text as NSString).boundingRect(
          with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 200),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: attrs,
          context: nil
        ).width
      )
      let fitted = valueLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: CGFloat.greatestFiniteMagnitude))
      labelWidth = min(maxLabelWidth, max(singleLineW, fitted.width, 1))
    }

    let labelHeight = text.isEmpty
      ? 0
      : ceil(
        (text as NSString).boundingRect(
          with: CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: attrs,
          context: nil
        ).height
      )

    let w = labelWidth
    let h = max(labelHeight, ceil(font.lineHeight))
    var f = CGRect.zero
    let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
    switch c.label.placement {
    case .none:
      break
    case .above:
      f = CGRect(x: (bounds.width - w) / 2, y: track.minY - pad - h, width: w, height: h)
    case .below:
      f = CGRect(x: (bounds.width - w) / 2, y: track.maxY + pad, width: w, height: h)
    case .leading:
      let x = rtl ? track.maxX + pad : track.minX - pad - w
      f = CGRect(x: x, y: track.midY - h / 2, width: w, height: h)
    case .trailing:
      let x = rtl ? track.minX - pad - w : track.maxX + pad
      f = CGRect(x: x, y: track.midY - h / 2, width: w, height: h)
    case .centeredOnTrack:
      f = CGRect(x: track.midX - w / 2, y: track.midY - h / 2, width: w, height: h)
    }
    valueLabel.frame = f
  }

  private struct LabelAxisInset {
    var vertical: CGFloat = 0
    var horizontal: CGFloat = 0
    var bothAxes: CGFloat = 0
  }

  private func labelIntrinsicAxisContribution() -> LabelAxisInset {
    guard configuration.label.placement != .none else { return LabelAxisInset() }
    let pad = configuration.label.padding
    let c = configuration
    var o = LabelAxisInset()
    let textHeight = labelMeasurementTextHeight()
    switch c.label.placement {
    case .none:
      break
    case .above, .below:
      o.vertical = textHeight + pad
    case .leading, .trailing:
      let sample = Self.labelSampleString(for: c)
      let wText = ceil(
        (sample as NSString).boundingRect(
          with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 200),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: [.font: c.label.font],
          context: nil
        ).width
      )
      let w = min(200, max(44, wText)) + pad
      o.horizontal = w
    case .centeredOnTrack:
      o.bothAxes = textHeight + pad
    }
    return o
  }

  private func applyInteractionModeFromConfiguration() {
    switch configuration.interaction.interactionMode {
    case .indicator:
      isUserInteractionEnabled = false
    case .button:
      isUserInteractionEnabled = isEnabled
    }
  }

  private func refreshTouchHapticWiring() {
    removeTarget(self, action: #selector(fkProgressBarTouchDownHaptic), for: .touchDown)
    removeTarget(self, action: #selector(fkProgressBarTouchUpHaptic), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside])
    guard configuration.interaction.interactionMode == .button else { return }
    guard configuration.interaction.touchHaptic != .none else { return }
    addTarget(self, action: #selector(fkProgressBarTouchDownHaptic), for: .touchDown)
    addTarget(self, action: #selector(fkProgressBarTouchUpHaptic), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside])
  }

  @objc private func fkProgressBarTouchDownHaptic() {
    switch configuration.interaction.touchHaptic {
    case .none:
      break
    case .lightImpactOnTouchDown:
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .selectionChangedOnTouchDown:
      UISelectionFeedbackGenerator().selectionChanged()
    }
  }

  @objc private func fkProgressBarTouchUpHaptic() {}

  private func updateTouchAppearance() {
    let mode = configuration.interaction.interactionMode
    let baseAlpha: CGFloat = (mode == .button && !isEnabled) ? configuration.interaction.disabledAlpha : 1
    let highlightFactor = (mode == .button && isEnabled && isHighlighted) ? configuration.interaction.highlightedAlphaMultiplier : 1
    let a = min(1, max(0.05, baseAlpha * highlightFactor))
    layerStack.container.opacity = Float(a)
    valueLabel.alpha = a
  }

  private func labelMeasurementTextHeight() -> CGFloat {
    let c = configuration
    let pad = configuration.label.padding
    let labelWidthProbe = max(80, bounds.width > 0 ? bounds.width - pad * 2 : 240)
    let font = c.label.font
    switch c.label.contentMode {
    case .formattedProgress:
      return ceil(font.lineHeight)
    case .customTitleOnly:
      let t = c.label.customTitle.isEmpty ? " " : c.label.customTitle
      return ceil(
        (t as NSString).boundingRect(
          with: CGSize(width: labelWidthProbe, height: CGFloat.greatestFiniteMagnitude),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: [.font: font],
          context: nil
        ).height
      )
    case .customTitleWhenIdle:
      let t = c.label.customTitle.isEmpty ? " " : c.label.customTitle
      let hTitle = (t as NSString).boundingRect(
        with: CGSize(width: labelWidthProbe, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
      ).height
      let hFmt = ceil(font.lineHeight)
      return ceil(max(hTitle, hFmt))
    case .customTitleWithProgressSubtitle:
      let body = c.label.customTitle.isEmpty ? "100%" : "\(c.label.customTitle)\n100%"
      return ceil(
        (body as NSString).boundingRect(
          with: CGSize(width: labelWidthProbe, height: CGFloat.greatestFiniteMagnitude),
          options: [.usesLineFragmentOrigin, .usesFontLeading],
          attributes: [.font: font],
          context: nil
        ).height
      )
    }
  }

  private static func labelSampleString(for c: FKProgressBarConfiguration) -> String {
    switch c.label.contentMode {
    case .formattedProgress:
      return "100%"
    case .customTitleOnly, .customTitleWhenIdle:
      return c.label.customTitle.isEmpty ? "100%" : c.label.customTitle
    case .customTitleWithProgressSubtitle:
      let t = c.label.customTitle.isEmpty ? "Title" : c.label.customTitle
      return "\(t)\n100%"
    }
  }

  private func updateAccessibility() {
    if let label = configuration.accessibility.customLabel, !label.isEmpty {
      accessibilityLabel = label
    } else if !configuration.label.customTitle.isEmpty,
              configuration.label.contentMode != .formattedProgress,
              configuration.label.placement != .none
    {
      accessibilityLabel = configuration.label.customTitle
    } else {
      accessibilityLabel = nil
    }
    if let hint = configuration.accessibility.customHint, !hint.isEmpty {
      accessibilityHint = hint
    } else {
      accessibilityHint = nil
    }
    accessibilityValue = FKProgressBarLabelFormatting.accessibilityValue(
      progress: progress,
      buffer: bufferProgress,
      configuration: configuration,
      isIndeterminate: isIndeterminate
    )
    if configuration.accessibility.treatAsFrequentUpdates {
      accessibilityTraits.insert(.updatesFrequently)
    } else {
      accessibilityTraits.remove(.updatesFrequently)
    }
    if configuration.interaction.interactionMode == .button {
      accessibilityTraits.insert(.button)
    } else {
      accessibilityTraits.remove(.button)
    }
  }
}
