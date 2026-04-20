//
// FKExpandableText.swift
//
// Main expandable text view based on UILabel.
//

import UIKit

/// A pure UIKit expandable/collapsible text component optimized for reusable list cells.
@MainActor
public final class FKExpandableText: UIView, FKExpandableTextHeightMeasuring {
  /// App-wide default configuration.
  ///
  /// Use this baseline to keep style consistent across screens, then override
  /// per instance when needed.
  public static var defaultConfiguration: FKExpandableTextConfiguration {
    get { FKExpandableTextManager.shared.defaultConfiguration }
    set { FKExpandableTextManager.shared.defaultConfiguration = newValue }
  }

  /// Shared state cache manager.
  ///
  /// Replace this value when you need a custom cache implementation.
  public static var stateCache: FKExpandableTextStateCaching = FKExpandableTextManager.shared

  /// Callback invoked when state changes.
  ///
  /// The callback is emitted after state transition is applied.
  public var onStateChange: ((FKExpandableTextStateContext) -> Void)?

  /// Unique key used by list reuse state cache.
  ///
  /// When set, cached state is restored automatically if available.
  public var stateIdentifier: String? {
    didSet {
      applyCachedStateIfNeeded()
    }
  }

  /// Current full configuration.
  ///
  /// Setting this property re-applies style, layout constraints, and interaction behavior.
  public var configuration: FKExpandableTextConfiguration {
    didSet {
      applyConfiguration()
    }
  }

  /// Plain text payload.
  ///
  /// Setting this value clears `attributedText` source and triggers layout refresh.
  public var text: String? {
    didSet {
      rawAttributedText = nil
      setNeedsLayout()
      invalidateIntrinsicContentSize()
    }
  }

  /// Rich text payload.
  ///
  /// Setting this value replaces plain text source and triggers layout refresh.
  public var attributedText: NSAttributedString? {
    didSet {
      rawAttributedText = attributedText
      setNeedsLayout()
      invalidateIntrinsicContentSize()
    }
  }

  /// Current expanded state.
  ///
  /// Use `setExpanded(_:animated:notify:)` or `toggle(animated:)` to mutate this value.
  public private(set) var displayState: FKExpandableTextDisplayState = .collapsed

  /// Whether content is currently truncated in collapsed mode.
  ///
  /// This value is re-evaluated during layout based on current width and style.
  public private(set) var isTruncated: Bool = false

  /// UILabel exposed for advanced external customization.
  public let textLabel = UILabel()

  /// Internal action button used for expand/collapse toggling.
  private let actionButton = FKExpandableTextButton()
  /// Gesture recognizer for text-tap trigger mode.
  private let tapGesture = UITapGestureRecognizer()
  /// Raw attributed source provided by caller before style normalization.
  private var rawAttributedText: NSAttributedString?

  /// Guard flag to ensure constraints are created once.
  private var didSetupConstraints = false
  /// Dynamic constraints affected by content insets.
  private var contentInsetsConstraints: [NSLayoutConstraint] = []
  /// Constraints used in `.bottomTrailing` button mode.
  private var bottomButtonConstraints: [NSLayoutConstraint] = []
  /// Constraints used in `.tailFollow` button mode.
  private var tailButtonConstraints: [NSLayoutConstraint] = []
  /// Bottom anchor used when button is hidden or inactive.
  private var noButtonBottomConstraint: NSLayoutConstraint?

  /// Creates component from frame-based initializer.
  public override init(frame: CGRect) {
    self.configuration = FKExpandableText.defaultConfiguration
    super.init(frame: frame)
    setupView()
    applyConfiguration()
  }

  /// Creates component from Interface Builder and applies default configuration.
  public required init?(coder: NSCoder) {
    self.configuration = FKExpandableText.defaultConfiguration
    super.init(coder: coder)
    setupView()
    applyConfiguration()
  }

  /// Lazily builds Auto Layout constraints before first layout pass.
  public override func updateConstraints() {
    if !didSetupConstraints {
      buildConstraints()
      didSetupConstraints = true
    }
    super.updateConstraints()
  }

  /// Re-evaluates truncation and visible state after size changes.
  public override func layoutSubviews() {
    super.layoutSubviews()
    refreshVisibleContentIfNeeded()
  }

  /// Returns intrinsic size based on current width and display state.
  public override var intrinsicContentSize: CGSize {
    guard bounds.width > 0 else {
      return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    let height = measuredHeight(for: bounds.width, state: displayState)
    return CGSize(width: UIView.noIntrinsicMetric, height: height)
  }

  /// Applies a full configuration.
  ///
  /// - Parameter configuration: Full style/behavior payload to apply.
  public func configure(_ configuration: FKExpandableTextConfiguration) {
    self.configuration = configuration
  }

  /// One-line builder for setup.
  ///
  /// - Parameter updates: Closure that mutates a temporary configuration copy.
  public func configure(_ updates: (inout FKExpandableTextConfiguration) -> Void) {
    var copy = configuration
    updates(&copy)
    configuration = copy
  }

  /// Sets plain text and optional state key in one call.
  ///
  /// - Parameters:
  ///   - text: Plain text content.
  ///   - stateIdentifier: Optional stable key for cache lookup and persistence.
  public func setText(
    _ text: String?,
    stateIdentifier: String? = nil
  ) {
    self.stateIdentifier = stateIdentifier
    self.text = text
  }

  /// Sets rich text and optional state key in one call.
  ///
  /// - Parameters:
  ///   - attributedText: Rich text content.
  ///   - stateIdentifier: Optional stable key for cache lookup and persistence.
  public func setAttributedText(
    _ attributedText: NSAttributedString?,
    stateIdentifier: String? = nil
  ) {
    self.stateIdentifier = stateIdentifier
    self.attributedText = attributedText
  }

  /// Updates expanded state manually.
  ///
  /// - Parameters:
  ///   - expanded: Target expanded flag.
  ///   - animated: Whether transition should animate.
  ///   - notify: Whether `onStateChange` callback should fire.
  public func setExpanded(
    _ expanded: Bool,
    animated: Bool = true,
    notify: Bool = true
  ) {
    let target: FKExpandableTextDisplayState = expanded ? .expanded : .collapsed
    updateState(target, animated: animated, notify: notify)
  }

  /// Toggles expanded/collapsed state.
  ///
  /// - Parameter animated: Whether transition should animate.
  public func toggle(animated: Bool = true) {
    setExpanded(displayState != .expanded, animated: animated)
  }

  /// Clears component-specific cached state.
  ///
  /// This API only removes state for current `stateIdentifier`.
  public func clearCachedState() {
    guard let stateIdentifier else { return }
    FKExpandableText.stateCache.removeState(for: stateIdentifier)
  }

  /// Measures view height for a specific width and display state.
  ///
  /// - Parameters:
  ///   - width: Available width for this component.
  ///   - state: Target display state used for line limit.
  /// - Returns: Full height including text, button, spacing, and insets.
  public func measuredHeight(for width: CGFloat, state: FKExpandableTextDisplayState) -> CGFloat {
    // Convert external width into inner text width by removing configured insets.
    let contentWidth = max(0, width - configuration.layoutStyle.contentInsets.left - configuration.layoutStyle.contentInsets.right)
    let text = resolvedAttributedText
    // Expanded state uses unlimited lines for full content height.
    let expandedTextHeight = FKExpandableTextTextBuilder.measuredHeight(
      for: text,
      width: contentWidth,
      maximumNumberOfLines: 0
    )
    // Collapsed height is measured with maximum line limit.
    let collapsedTextHeight = FKExpandableTextTextBuilder.measuredHeight(
      for: text,
      width: contentWidth,
      maximumNumberOfLines: configuration.behavior.collapsedNumberOfLines
    )
    // Compare full/collapsed heights instead of relying on line counting.
    // This is more robust across different paragraph styles and layout phases.
    let truncated = expandedTextHeight > collapsedTextHeight + 0.5

    // Button area is included only when text is truncatable.
    let buttonHeight = resolvedButtonHeight(for: state, isTruncated: truncated)
    let spacing = resolvedButtonSpacing(isTruncated: truncated)
    let textHeight = state == .expanded ? expandedTextHeight : collapsedTextHeight

    return ceil(configuration.layoutStyle.contentInsets.top + textHeight + spacing + buttonHeight + configuration.layoutStyle.contentInsets.bottom)
  }

  /// Pre-calculates component height with cache support for high-volume lists.
  ///
  /// Use this API in table/collection sizing paths to keep scrolling smooth.
  ///
  /// - Parameters:
  ///   - text: Plain text input.
  ///   - attributedText: Optional attributed text input.
  ///   - width: Available component width.
  ///   - state: Target state (`collapsed` or `expanded`).
  ///   - configuration: Optional custom configuration for measurement.
  ///   - cacheKey: Optional height cache key.
  /// - Returns: Measured height.
  public static func preferredHeight(
    text: String?,
    attributedText: NSAttributedString? = nil,
    width: CGFloat,
    state: FKExpandableTextDisplayState,
    configuration: FKExpandableTextConfiguration = FKExpandableText.defaultConfiguration,
    cacheKey: String? = nil
  ) -> CGFloat {
    // Reuse cached value when caller provides a stable key.
    if let cacheKey, let cached = FKExpandableTextManager.shared.height(for: cacheKey) {
      return cached
    }

    // Build normalized styled text to align with runtime rendering output.
    let styleText = FKExpandableTextTextBuilder.styledAttributedText(
      plainText: text,
      attributedText: attributedText,
      style: configuration.textStyle
    )
    // Inner content width excludes view insets.
    let contentWidth = max(0, width - configuration.layoutStyle.contentInsets.left - configuration.layoutStyle.contentInsets.right)
    let fullHeight = FKExpandableTextTextBuilder.measuredHeight(for: styleText, width: contentWidth, maximumNumberOfLines: 0)
    let collapsedHeight = FKExpandableTextTextBuilder.measuredHeight(
      for: styleText,
      width: contentWidth,
      maximumNumberOfLines: configuration.behavior.collapsedNumberOfLines
    )
    // Compare full/collapsed heights instead of line counting to avoid
    // inconsistencies under different text attributes and layout timing.
    let truncated = fullHeight > collapsedHeight + 0.5

    // Button height depends on active state title and content insets.
    let buttonTitle = (state == .expanded ? configuration.buttonStyle.collapseTitle : configuration.buttonStyle.expandTitle) as NSString
    let buttonSize = buttonTitle.size(withAttributes: [.font: configuration.buttonStyle.font])
    let buttonHeight = truncated ? ceil(buttonSize.height + configuration.buttonStyle.contentInsets.top + configuration.buttonStyle.contentInsets.bottom) : 0
    let spacing = truncated && configuration.layoutStyle.buttonPosition == .bottomTrailing ? configuration.layoutStyle.textButtonSpacing : 0
    let textHeight = state == .expanded ? fullHeight : collapsedHeight
    let result = ceil(configuration.layoutStyle.contentInsets.top + textHeight + spacing + buttonHeight + configuration.layoutStyle.contentInsets.bottom)

    // Persist measured value for future sizing passes.
    if let cacheKey {
      FKExpandableTextManager.shared.setHeight(result, for: cacheKey)
    }
    return result
  }
}

// MARK: - Private

private extension FKExpandableText {
  /// Returns caller text normalized with current style.
  var resolvedAttributedText: NSAttributedString {
    FKExpandableTextTextBuilder.styledAttributedText(
      plainText: text,
      attributedText: rawAttributedText,
      style: configuration.textStyle
    )
  }

  /// Builds internal subviews and gesture wiring.
  func setupView() {
    isAccessibilityElement = false
    clipsToBounds = false

    textLabel.numberOfLines = 0
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textLabel)

    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    addSubview(actionButton)

    tapGesture.addTarget(self, action: #selector(handleTextTap))
    textLabel.addGestureRecognizer(tapGesture)
    textLabel.isUserInteractionEnabled = true
  }

  /// Creates base constraints and initializes mode-specific groups.
  func buildConstraints() {
    // Keep a low-priority bottom anchor for states without visible button area.
    let noButtonBottom = textLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
    noButtonBottom.priority = .defaultHigh
    noButtonBottomConstraint = noButtonBottom

    // Prepare button constraints for bottom trailing layout mode.
    bottomButtonConstraints = [
      actionButton.topAnchor.constraint(equalTo: textLabel.bottomAnchor),
      actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
      actionButton.bottomAnchor.constraint(equalTo: bottomAnchor)
    ]
    bottomButtonConstraints[0].priority = .required

    // Prepare button constraints for tail-follow layout mode.
    tailButtonConstraints = [
      actionButton.trailingAnchor.constraint(equalTo: textLabel.trailingAnchor),
      actionButton.bottomAnchor.constraint(equalTo: textLabel.bottomAnchor)
    ]

    NSLayoutConstraint.activate([noButtonBottom])
    updateContentInsetsConstraints()
    updateButtonPositionConstraints()
  }

  /// Rebuilds constraints that depend on content insets.
  func updateContentInsetsConstraints() {
    NSLayoutConstraint.deactivate(contentInsetsConstraints)
    contentInsetsConstraints = [
      textLabel.topAnchor.constraint(equalTo: topAnchor, constant: configuration.layoutStyle.contentInsets.top),
      textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: configuration.layoutStyle.contentInsets.left),
      textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -configuration.layoutStyle.contentInsets.right),
      textLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -configuration.layoutStyle.contentInsets.bottom)
    ]
    NSLayoutConstraint.activate(contentInsetsConstraints)
  }

  /// Activates constraints for current button position mode.
  func updateButtonPositionConstraints() {
    // `applyConfiguration()` may run before `buildConstraints()`.
    // Avoid indexing empty arrays until constraints are initialized.
    guard bottomButtonConstraints.count == 3, tailButtonConstraints.count == 2 else {
      return
    }
    NSLayoutConstraint.deactivate(bottomButtonConstraints + tailButtonConstraints)

    switch configuration.layoutStyle.buttonPosition {
    case .bottomTrailing:
      // Button sits below text with configurable spacing.
      bottomButtonConstraints[0].constant = configuration.layoutStyle.textButtonSpacing
      bottomButtonConstraints[1].constant = -configuration.layoutStyle.contentInsets.right
      bottomButtonConstraints[2].constant = -configuration.layoutStyle.contentInsets.bottom
      NSLayoutConstraint.activate(bottomButtonConstraints)
      noButtonBottomConstraint?.constant = -configuration.layoutStyle.contentInsets.bottom
    case .tailFollow:
      // Button overlaps label area and follows trailing/bottom edge.
      tailButtonConstraints[0].constant = 0
      NSLayoutConstraint.activate(tailButtonConstraints)
      noButtonBottomConstraint?.constant = -configuration.layoutStyle.contentInsets.bottom
    }
  }

  /// Applies visual/interaction configuration to current view hierarchy.
  func applyConfiguration() {
    textLabel.textAlignment = configuration.textStyle.alignment
    textLabel.lineBreakMode = configuration.textStyle.lineBreakMode
    actionButton.apply(style: configuration.buttonStyle, state: displayState)
    updateButtonPositionConstraints()
    updateInteractionStatus()
    setNeedsLayout()
    invalidateIntrinsicContentSize()
  }

  /// Refreshes visible text/button state after size or content changes.
  func refreshVisibleContentIfNeeded() {
    guard bounds.width > 0 else { return }

    // Rebuild styled text every pass to ensure consistent style propagation.
    let styledText = resolvedAttributedText
    textLabel.attributedText = styledText

    // Determine whether text exceeds collapsed line limit under current width.
    // Use container width instead of `textLabel.bounds.width` to avoid
    // transient zero-width reads during early layout passes in stack/list cells.
    let contentWidth = max(
      0,
      bounds.width - configuration.layoutStyle.contentInsets.left - configuration.layoutStyle.contentInsets.right
    )
    let expandedHeight = FKExpandableTextTextBuilder.measuredHeight(
      for: styledText,
      width: contentWidth,
      maximumNumberOfLines: 0
    )
    let collapsedHeight = FKExpandableTextTextBuilder.measuredHeight(
      for: styledText,
      width: contentWidth,
      maximumNumberOfLines: configuration.behavior.collapsedNumberOfLines
    )
    isTruncated = expandedHeight > collapsedHeight + 0.5

    // Fixed state overrides user-driven state transitions.
    if let fixedState = configuration.behavior.fixedState {
      displayState = fixedState
    }

    // Short text is always fully shown and does not require collapse UI.
    let targetLines: Int
    if !isTruncated {
      targetLines = 0
      displayState = .expanded
    } else {
      targetLines = displayState == .expanded ? 0 : configuration.behavior.collapsedNumberOfLines
    }
    textLabel.numberOfLines = targetLines

    // Auto-hide button when content is not truncated.
    actionButton.isHidden = !isTruncated
    actionButton.apply(style: configuration.buttonStyle, state: displayState)
    updateInteractionStatus()
  }

  /// Updates gesture/button availability from behavior and current truncation.
  func updateInteractionStatus() {
    let canInteract = configuration.behavior.isInteractionEnabled && configuration.behavior.fixedState == nil && isTruncated
    actionButton.isEnabled = canInteract && configuration.behavior.triggerMode.contains(.button)
    tapGesture.isEnabled = canInteract && configuration.behavior.triggerMode.contains(.text)
  }

  /// Applies state transition, animation, cache write, and optional callback.
  func updateState(
    _ state: FKExpandableTextDisplayState,
    animated: Bool,
    notify: Bool
  ) {
    guard displayState != state else { return }
    guard configuration.behavior.fixedState == nil else { return }
    displayState = state

    // Persist state for reusable list restoration.
    if let stateIdentifier, configuration.behavior.usesStateCache {
      FKExpandableText.stateCache.setState(state, for: stateIdentifier)
    }

    // Animate line limit and button title changes together for smooth transition.
    let updates = { [weak self] in
      guard let self else { return }
      self.textLabel.numberOfLines = state == .expanded ? 0 : self.configuration.behavior.collapsedNumberOfLines
      self.actionButton.apply(style: self.configuration.buttonStyle, state: state)
      self.invalidateIntrinsicContentSize()
      self.superview?.layoutIfNeeded()
      self.layoutIfNeeded()
    }

    if animated {
      UIView.animate(withDuration: configuration.layoutStyle.animationDuration, animations: updates)
    } else {
      updates()
    }

    if notify {
      // Emit callback after state commit so listeners can refresh layout safely.
      onStateChange?(FKExpandableTextStateContext(state: state, isTruncated: isTruncated, identifier: stateIdentifier))
    }
  }

  /// Applies cached state when identifier and cache policy are both available.
  func applyCachedStateIfNeeded() {
    guard
      configuration.behavior.usesStateCache,
      let stateIdentifier,
      let cached = FKExpandableText.stateCache.state(for: stateIdentifier)
    else {
      return
    }
    displayState = cached
    setNeedsLayout()
  }

  /// Returns vertical spacing between text and button for current layout mode.
  func resolvedButtonSpacing(isTruncated: Bool) -> CGFloat {
    guard isTruncated, configuration.layoutStyle.buttonPosition == .bottomTrailing else {
      return 0
    }
    return configuration.layoutStyle.textButtonSpacing
  }

  /// Returns button height for current title and style.
  func resolvedButtonHeight(
    for state: FKExpandableTextDisplayState,
    isTruncated: Bool
  ) -> CGFloat {
    guard isTruncated else { return 0 }
    let title = state == .expanded ? configuration.buttonStyle.collapseTitle : configuration.buttonStyle.expandTitle
    let size = (title as NSString).size(withAttributes: [.font: configuration.buttonStyle.font])
    return ceil(size.height + configuration.buttonStyle.contentInsets.top + configuration.buttonStyle.contentInsets.bottom)
  }

  /// Handles button tap trigger.
  @objc
  func handleButtonTap() {
    toggle(animated: true)
  }

  /// Handles text tap trigger.
  @objc
  func handleTextTap() {
    toggle(animated: true)
  }
}
