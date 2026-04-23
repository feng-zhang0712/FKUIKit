import UIKit

// MARK: - Delegate

/// Delegate for the primary action button (alternative to `actionHandler` closure).
public protocol FKEmptyStateViewDelegate: AnyObject {
  /// Called when the user taps an action button.
  ///
  /// - Important: The callback carries a full `FKEmptyStateAction` so hosts can route by `id`
  ///   (recommended) or by `kind` (UI slot role).
  func emptyStateView(_ view: FKEmptyStateView, didTap action: FKEmptyStateAction)
}

// MARK: - FKEmptyStateView

/// Full-screen overlay for empty, loading, error, or custom-state UI.
///
/// Prefer adding to `UIViewController.view` or a `UIScrollView` subview — **not** `UITableView.backgroundView`, so refresh controls remain visible above table backgrounds.
///
/// Touch handling: the view fills the host bounds and intercepts touches; `UIGestureRecognizerDelegate` avoids stealing taps from `UIControl` subclasses (e.g. the action button). Optional dimming uses `blockingOverlayAlpha`.
///
/// Accessibility notes:
/// - The overlay does not set `accessibilityViewIsModal` by default to avoid trapping focus in
///   complex screens. Instead, it posts a VoiceOver announcement on state changes when enabled
///   (`FKEmptyStateModel.announcesStateChanges`).
/// - Title is marked as `.header` to improve navigation in VoiceOver rotor.
public final class FKEmptyStateView: UIView, UIGestureRecognizerDelegate {

  // MARK: Public

  /// Optional delegate for button taps.
  public weak var delegate: FKEmptyStateViewDelegate?
  /// Closure invoked when any action button is tapped (primary / secondary / tertiary).
  ///
  /// Use `action.id` as a stable routing key. The built-in renderer auto-generates a primary
  /// action with id `"primary"` when you only set the legacy `buttonStyle.title`.
  public var actionHandler: ((FKEmptyStateAction) -> Void)?
  /// Closure invoked when users tap the placeholder background area.
  public var viewTapHandler: FKVoidHandler?
  /// Snapshot of the last `apply(_:animated:)` input (for debugging / re-application).
  public private(set) var model: FKEmptyStateModel = FKEmptyStateModel()

  // MARK: Private (subviews & state)

  /// Full-bleed dimming layer between gradient and content (`blockingOverlayAlpha`).
  private let blockingDimmingView = UIView()
  /// Horizontal + vertical centering container for the stack (respects safe area & keyboard).
  private let containerView = UIView()
  /// Vertical stack for illustration, text, spinner, and button.
  private let stackView = UIStackView()
  /// Hosts `model.customAccessoryView` when provided.
  private let customAccessoryContainer = UIView()
  private let imageView = UIImageView()
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
  private let primaryButton = UIButton(type: .system)
  private let secondaryButton = UIButton(type: .system)
  private let tertiaryButton = UIButton(type: .system)
  private let actionsStack = UIStackView()
  private let headerSlotContainer = UIView()
  private let mediaSlotContainer = UIView()
  private let contentSlotContainer = UIView()
  private let actionsSlotContainer = UIView()
  private let footerSlotContainer = UIView()
  private var loadingIndicator = UIActivityIndicatorView(style: .large)
  /// Tracks style to avoid recreating the indicator unnecessarily.
  private var appliedIndicatorStyle: UIActivityIndicatorView.Style?
  /// Background tap → `endEditing(true)` when `supportsTapToDismissKeyboard` is enabled.
  private let keyboardDismissTap = UITapGestureRecognizer()
  private var gradientLayer: CAGradientLayer?
  private var imageWidthConstraint: NSLayoutConstraint?
  private var imageHeightConstraint: NSLayoutConstraint?
  private var containerMaxWidthConstraint: NSLayoutConstraint?
  private var keyboardBottomConstraint: NSLayoutConstraint?
  private var containerCenterYConstraint: NSLayoutConstraint?
  private var containerTopConstraint: NSLayoutConstraint?
  private var lastAnnouncementSignature: String?

  // MARK: Lifecycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer?.frame = bounds
  }

  // MARK: Public API

  /// Applies `model` to labels, images, spinner, and layout. Must run on the main thread.
  ///
  /// - Parameters:
  ///   - model: New configuration; `phase == .content` is a no-op visually (caller should hide the overlay).
  ///   - animated: Cross-dissolve transition when `true`.
  public func apply(_ model: FKEmptyStateModel, animated: Bool = false) {
    fk_emptyStateAssertMainThread()
    self.model = model
    let updates = { self.updateUI(with: model) }
    if animated, !UIAccessibility.isReduceMotionEnabled {
      UIView.transition(with: self, duration: model.fadeDuration, options: .transitionCrossDissolve, animations: updates)
    } else {
      updates()
    }
  }

  /// Manually assigns a custom illustration view (e.g. Lottie). `nil` clears the container.
  public func setCustomAccessoryView(_ view: UIView?) {
    fk_emptyStateAssertMainThread()
    customAccessoryContainer.subviews.forEach { $0.removeFromSuperview() }
    guard let view else {
      customAccessoryContainer.isHidden = true
      return
    }
    view.translatesAutoresizingMaskIntoConstraints = false
    customAccessoryContainer.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: customAccessoryContainer.topAnchor),
      view.leadingAnchor.constraint(equalTo: customAccessoryContainer.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: customAccessoryContainer.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: customAccessoryContainer.bottomAnchor),
    ])
    customAccessoryContainer.isHidden = false
  }

  // MARK: Setup

  private func setupViews() {
    isHidden = true
    alpha = 0
    isUserInteractionEnabled = true
    accessibilityIdentifier = "fk.emptyState.root"

    blockingDimmingView.translatesAutoresizingMaskIntoConstraints = false
    blockingDimmingView.isUserInteractionEnabled = false
    addSubview(blockingDimmingView)

    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(stackView)

    customAccessoryContainer.translatesAutoresizingMaskIntoConstraints = false

    imageView.contentMode = .scaleAspectFit
    imageView.setContentCompressionResistancePriority(.required, for: .vertical)
    imageView.accessibilityIdentifier = "fk.emptyState.image"
    imageView.isAccessibilityElement = false

    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    titleLabel.accessibilityIdentifier = "fk.emptyState.title"
    titleLabel.isAccessibilityElement = true
    titleLabel.accessibilityTraits = [.header]

    descriptionLabel.numberOfLines = 0
    descriptionLabel.textAlignment = .center
    descriptionLabel.accessibilityIdentifier = "fk.emptyState.description"
    descriptionLabel.isAccessibilityElement = true

    actionsStack.axis = .vertical
    actionsStack.alignment = .center
    actionsStack.distribution = .fill
    actionsStack.spacing = 10
    actionsStack.translatesAutoresizingMaskIntoConstraints = false
    actionsStack.accessibilityIdentifier = "fk.emptyState.actions"

    configureButton(primaryButton, identifier: "fk.emptyState.primaryButton", action: #selector(handlePrimaryTap))
    configureButton(secondaryButton, identifier: "fk.emptyState.secondaryButton", action: #selector(handleSecondaryTap))
    configureButton(tertiaryButton, identifier: "fk.emptyState.tertiaryButton", action: #selector(handleTertiaryTap))

    headerSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    mediaSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    contentSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    actionsSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    footerSlotContainer.translatesAutoresizingMaskIntoConstraints = false

    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.accessibilityIdentifier = "fk.emptyState.loading"
    loadingIndicator.isAccessibilityElement = true

    keyboardDismissTap.addTarget(self, action: #selector(handleBackgroundTap))
    keyboardDismissTap.cancelsTouchesInView = false
    keyboardDismissTap.delegate = self
    addGestureRecognizer(keyboardDismissTap)

    containerMaxWidthConstraint = containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
    containerMaxWidthConstraint?.isActive = true

    let centerY = containerView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
    centerY.priority = UILayoutPriority(750)
    centerY.isActive = true
    containerCenterYConstraint = centerY

    let topConstraint = containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
    topConstraint.priority = UILayoutPriority(500)
    topConstraint.isActive = false
    containerTopConstraint = topConstraint

    NSLayoutConstraint.activate([
      blockingDimmingView.topAnchor.constraint(equalTo: topAnchor),
      blockingDimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      blockingDimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
      blockingDimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),

      containerView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
      containerView.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor),
      containerView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor),

      stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    let keyboardBottom = containerView.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: -12)
    keyboardBottom.priority = .required
    keyboardBottom.isActive = true
    keyboardBottomConstraint = keyboardBottom
  }

  private func configureButton(_ button: UIButton, identifier: String, action: Selector) {
    button.addTarget(self, action: action, for: .touchUpInside)
    button.titleLabel?.numberOfLines = 1
    button.accessibilityIdentifier = identifier
    button.isAccessibilityElement = true
  }

  // MARK: UI update

  private func updateUI(with model: FKEmptyStateModel) {
    backgroundColor = model.backgroundColor
    updateGradient(with: model)

    blockingDimmingView.backgroundColor = UIColor.black.withAlphaComponent(model.blockingOverlayAlpha)

    stackView.spacing = model.verticalSpacing
    containerMaxWidthConstraint?.constant = model.maxContentWidth

    let insets = model.contentInsets
    directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: insets.top,
      leading: insets.left,
      bottom: insets.bottom,
      trailing: insets.right
    )

    // Recreate the activity indicator only when style changes.
    // This avoids unnecessary view churn while still supporting dynamic style switching.
    if appliedIndicatorStyle != model.activityIndicatorStyle {
      loadingIndicator.removeFromSuperview()
      loadingIndicator = UIActivityIndicatorView(style: model.activityIndicatorStyle)
      loadingIndicator.hidesWhenStopped = true
      appliedIndicatorStyle = model.activityIndicatorStyle
    }

    syncCustomAccessoryIfNeeded(model: model)

    imageView.image = model.image
    applyImageConstraints(model: model)

    titleLabel.textColor = model.titleColor
    titleLabel.font = model.titleFont
    descriptionLabel.textColor = model.descriptionColor
    descriptionLabel.font = model.descriptionFont
    titleLabel.textAlignment = model.textAlignment
    descriptionLabel.textAlignment = model.textAlignment

    // Allow forcing layout direction for QA/preview (e.g. RTL verification).
    // When unset, the view follows system direction.
    if let forced = model.forcedLayoutDirection {
      semanticContentAttribute = (forced == .rightToLeft) ? .forceRightToLeft : .forceLeftToRight
    } else {
      semanticContentAttribute = .unspecified
    }

    switch model.phase {
    case .content:
      break
    case .loading:
      applyLoadingPhase(model: model)
    case .empty, .error, .custom:
      applyContentPhase(model: model)
    }

    // Background tap optionally dismisses keyboard; the gesture recognizer will not steal taps
    // from buttons/controls due to `gestureRecognizer(_:shouldReceive:)`.
    keyboardDismissTap.isEnabled = model.supportsTapToDismissKeyboard
    // Keyboard-aware positioning is implemented via `keyboardLayoutGuide` when enabled.
    keyboardBottomConstraint?.isActive = model.adjustsPositionForKeyboard
    updateContentPosition(with: model)

    applySlots(model: model)
    applyAccessibility(model: model)
    announceIfNeeded(model: model)
  }

  // MARK: Loading layout

  private func applyLoadingPhase(model: FKEmptyStateModel) {
    let message = model.loadingMessage ?? model.title
    titleLabel.text = message
    titleLabel.isHidden = model.isTitleHidden || message?.isEmpty != false
    let showDesc = !model.hidesDescriptionForLoadingPhase && !(model.description?.isEmpty ?? true)
    descriptionLabel.text = model.description
    descriptionLabel.isHidden = model.isDescriptionHidden || !showDesc

    imageView.isHidden = true
    customAccessoryContainer.isHidden = true

    loadingIndicator.color = model.loadingTintColor
    loadingIndicator.startAnimating()

    applyActions(model: model, enforcedRetryTitle: nil)
    actionsStack.isHidden = true

    rebuildStack(orderedViews: [
      headerSlotContainer,
      loadingIndicator,
      titleLabel,
      descriptionLabel,
      footerSlotContainer,
    ])
  }

  // MARK: Empty / error layout

  private func applyContentPhase(model: FKEmptyStateModel) {
    loadingIndicator.stopAnimating()

    titleLabel.text = model.title
    titleLabel.isHidden = model.isTitleHidden || model.title?.isEmpty != false

    descriptionLabel.text = model.description
    descriptionLabel.isHidden = model.isDescriptionHidden || model.description?.isEmpty != false

    let imageHiddenFlag = model.isImageHidden || model.image == nil
    let customMissing = model.customAccessoryView == nil && customAccessoryContainer.subviews.isEmpty
    switch model.customAccessoryPlacement {
    case .replaceImage:
      imageView.isHidden = true
      customAccessoryContainer.isHidden = customMissing
    default:
      imageView.isHidden = imageHiddenFlag
      customAccessoryContainer.isHidden = customMissing
    }

    var enforcedRetry: String?
    if model.phase == .error {
      enforcedRetry = FKEmptyStateModel.defaultRetryButtonTitle
    }
    applyActions(model: model, enforcedRetryTitle: enforcedRetry)

    rebuildStack(orderedViews: contentBlocks(model: model))
  }

  /// Builds stack order for empty/error based on `customAccessoryPlacement`.
  private func contentBlocks(model: FKEmptyStateModel) -> [UIView] {
    let imageBlock = imageView
    let customBlock = customAccessoryContainer
    switch model.customAccessoryPlacement {
    case .replaceImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        customBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .aboveImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        customBlock,
        imageBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .belowImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        imageBlock,
        customBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .belowDescription:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        imageBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        customBlock,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    }
  }

  private func rebuildStack(orderedViews: [UIView]) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    for v in orderedViews {
      if v === headerSlotContainer || v === mediaSlotContainer || v === contentSlotContainer || v === actionsSlotContainer || v === footerSlotContainer {
        v.isHidden = v.subviews.isEmpty
      }
      if v === actionsStack {
        v.isHidden = actionsStack.arrangedSubviews.isEmpty || actionsStack.isHidden
      }
      stackView.addArrangedSubview(v)
    }
  }

  private func syncCustomAccessoryIfNeeded(model: FKEmptyStateModel) {
    if model.customAccessoryView == nil {
      setCustomAccessoryView(nil)
      return
    }
    if let provided = model.customAccessoryView, provided.superview !== customAccessoryContainer {
      setCustomAccessoryView(provided)
    }
  }

  private func applyImageConstraints(model: FKEmptyStateModel) {
    if let imageSize = model.imageSize {
      if imageWidthConstraint == nil {
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
      }
      if imageHeightConstraint == nil {
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
      }
      imageWidthConstraint?.constant = imageSize.width
      imageHeightConstraint?.constant = imageSize.height
      imageWidthConstraint?.isActive = true
      imageHeightConstraint?.isActive = true
    } else {
      imageWidthConstraint?.isActive = false
      imageHeightConstraint?.isActive = false
    }
  }

  private func updateGradient(with model: FKEmptyStateModel) {
    guard !model.gradientColors.isEmpty else {
      gradientLayer?.removeFromSuperlayer()
      gradientLayer = nil
      return
    }
    let layer = gradientLayer ?? CAGradientLayer()
    layer.colors = model.gradientColors.map(\.cgColor)
    layer.startPoint = model.gradientStartPoint
    layer.endPoint = model.gradientEndPoint
    layer.frame = bounds
    if layer.superlayer == nil {
      self.layer.insertSublayer(layer, at: 0)
    }
    gradientLayer = layer
  }

  /// Applies button styling while remaining compatible with iOS 13+.
  private func applyPrimaryButtonStyle(model: FKEmptyStateModel, title: String?) {
    if #available(iOS 15.0, *) {
      var buttonConfig = UIButton.Configuration.filled()
      buttonConfig.title = title
      buttonConfig.baseBackgroundColor = model.buttonStyle.backgroundColor
      buttonConfig.baseForegroundColor = model.buttonStyle.titleColor
      buttonConfig.cornerStyle = .fixed
      buttonConfig.contentInsets = NSDirectionalEdgeInsets(
        top: model.buttonStyle.contentInsets.top,
        leading: model.buttonStyle.contentInsets.left,
        bottom: model.buttonStyle.contentInsets.bottom,
        trailing: model.buttonStyle.contentInsets.right
      )
      primaryButton.configuration = buttonConfig
      primaryButton.setTitle(nil, for: .normal)
    } else {
      primaryButton.configuration = nil
      primaryButton.setTitle(title, for: .normal)
      primaryButton.setTitleColor(model.buttonStyle.titleColor, for: .normal)
      primaryButton.contentEdgeInsets = model.buttonStyle.contentInsets
      primaryButton.backgroundColor = model.buttonStyle.backgroundColor
    }
    primaryButton.titleLabel?.font = model.buttonStyle.font
    primaryButton.layer.cornerRadius = model.buttonStyle.cornerRadius
    primaryButton.layer.masksToBounds = true
    primaryButton.layer.borderWidth = model.buttonStyle.borderWidth
    primaryButton.layer.borderColor = model.buttonStyle.borderColor?.cgColor
  }

  private func applySecondaryButtonStyle(model: FKEmptyStateModel, title: String?) {
    if #available(iOS 15.0, *) {
      var cfg = UIButton.Configuration.bordered()
      cfg.title = title
      cfg.baseForegroundColor = model.buttonStyle.backgroundColor
      cfg.cornerStyle = .fixed
      cfg.contentInsets = NSDirectionalEdgeInsets(
        top: model.buttonStyle.contentInsets.top,
        leading: model.buttonStyle.contentInsets.left,
        bottom: model.buttonStyle.contentInsets.bottom,
        trailing: model.buttonStyle.contentInsets.right
      )
      secondaryButton.configuration = cfg
      secondaryButton.setTitle(nil, for: .normal)
    } else {
      secondaryButton.configuration = nil
      secondaryButton.setTitle(title, for: .normal)
      secondaryButton.setTitleColor(model.buttonStyle.backgroundColor, for: .normal)
      secondaryButton.contentEdgeInsets = model.buttonStyle.contentInsets
      secondaryButton.backgroundColor = .clear
      secondaryButton.layer.borderWidth = 1
      secondaryButton.layer.borderColor = model.buttonStyle.backgroundColor.cgColor
    }
    secondaryButton.titleLabel?.font = model.buttonStyle.font
    secondaryButton.layer.cornerRadius = model.buttonStyle.cornerRadius
    secondaryButton.layer.masksToBounds = true
  }

  private func applyTertiaryButtonStyle(model: FKEmptyStateModel, title: String?) {
    tertiaryButton.configuration = nil
    tertiaryButton.setTitle(title, for: .normal)
    tertiaryButton.setTitleColor(model.buttonStyle.backgroundColor, for: .normal)
    tertiaryButton.titleLabel?.font = model.buttonStyle.font
    tertiaryButton.backgroundColor = .clear
    tertiaryButton.layer.borderWidth = 0
  }

  private func applyActions(model: FKEmptyStateModel, enforcedRetryTitle: String?) {
    actionsStack.arrangedSubviews.forEach {
      actionsStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    var actions = model.actions
    var legacyPrimaryTitle = model.buttonStyle.title

    if model.phase == .error, (actions.primary?.title.isEmpty ?? true), (legacyPrimaryTitle?.isEmpty ?? true) {
      legacyPrimaryTitle = enforcedRetryTitle
    }

    // Backward-compat: allow a single legacy button title to be rendered as a primary action.
    // This keeps the model ergonomic for simple screens while still emitting a typed action.
    if actions.primary == nil, let t = legacyPrimaryTitle, !t.isEmpty {
      actions.primary = FKEmptyStateAction(id: "primary", title: t, kind: .primary)
    }

    if let p = actions.primary {
      applyPrimaryButtonStyle(model: model, title: p.title)
      primaryButton.isEnabled = p.isEnabled && !p.isLoading
      actionsStack.addArrangedSubview(primaryButton)
    }
    if let s = actions.secondary {
      applySecondaryButtonStyle(model: model, title: s.title)
      secondaryButton.isEnabled = s.isEnabled && !s.isLoading
      actionsStack.addArrangedSubview(secondaryButton)
    }
    if let t = actions.tertiary {
      applyTertiaryButtonStyle(model: model, title: t.title)
      tertiaryButton.isEnabled = t.isEnabled && !t.isLoading
      actionsStack.addArrangedSubview(tertiaryButton)
    }

    let shouldHide = actionsStack.arrangedSubviews.isEmpty || model.isButtonHidden
    actionsStack.isHidden = shouldHide && model.phase != .error
  }

  private func applySlots(model: FKEmptyStateModel) {
    replaceSlot(in: headerSlotContainer, with: model.headerSlot)
    replaceSlot(in: mediaSlotContainer, with: model.mediaSlot)
    replaceSlot(in: contentSlotContainer, with: model.contentSlot)
    replaceSlot(in: actionsSlotContainer, with: model.actionsSlot)
    replaceSlot(in: footerSlotContainer, with: model.footerSlot)
  }

  private func replaceSlot(in container: UIView, with view: UIView?) {
    container.subviews.forEach { $0.removeFromSuperview() }
    guard let view else { return }
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: container.topAnchor),
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  private func applyAccessibility(model: FKEmptyStateModel) {
    isAccessibilityElement = false
    accessibilityViewIsModal = false
  }

  private func announcementSignature(model: FKEmptyStateModel) -> String {
    let title = model.title ?? ""
    let desc = model.description ?? ""
    return "\(model.phase)|\(model.type.rawValue)|\(title)|\(desc)"
  }

  private func announceIfNeeded(model: FKEmptyStateModel) {
    guard model.announcesStateChanges else { return }
    guard !isHidden, alpha > 0.01 else { return }
    guard UIAccessibility.isVoiceOverRunning else { return }
    guard model.phase != .content else { return }

    let sig = announcementSignature(model: model)
    if sig == lastAnnouncementSignature { return }
    lastAnnouncementSignature = sig

    let message = [model.title, model.description]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
    guard !message.isEmpty else { return }
    // We use `.announcement` (not `.screenChanged`) to avoid interrupting navigation context
    // for users who keep exploring the underlying screen while the overlay appears.
    UIAccessibility.post(notification: .announcement, argument: message)
  }

  /// Updates container constraints according to alignment and offset preferences.
  private func updateContentPosition(with model: FKEmptyStateModel) {
    switch model.contentAlignment {
    case .center:
      containerCenterYConstraint?.isActive = true
      containerCenterYConstraint?.constant = model.verticalOffset
      containerTopConstraint?.isActive = false
    case .top:
      containerCenterYConstraint?.isActive = false
      containerTopConstraint?.isActive = true
      containerTopConstraint?.constant = model.contentInsets.top + model.verticalOffset
    }
  }

  // MARK: UIGestureRecognizerDelegate

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    // Walk up the hierarchy instead of checking only `touch.view`.
    // Some button internals report label/image subviews as the touched view; without this
    // ancestor check, background tap handlers may fire when users interact near CTA content.
    var current: UIView? = touch.view
    while let view = current {
      if view is UIControl { return false }
      current = view.superview
    }
    return true
  }

  // MARK: Actions

  @objc private func handlePrimaryTap() { emitAction(kind: .primary) }
  @objc private func handleSecondaryTap() { emitAction(kind: .secondary) }
  @objc private func handleTertiaryTap() { emitAction(kind: .tertiary) }

  private func emitAction(kind: FKEmptyStateActionKind) {
    let action: FKEmptyStateAction = {
      switch kind {
      case .primary:
        return model.actions.primary ?? FKEmptyStateAction(id: "primary", title: "", kind: .primary)
      case .secondary:
        return model.actions.secondary ?? FKEmptyStateAction(id: "secondary", title: "", kind: .secondary)
      case .tertiary:
        return model.actions.tertiary ?? FKEmptyStateAction(id: "tertiary", title: "", kind: .tertiary)
      case .link:
        return FKEmptyStateAction(id: "link", title: "", kind: .link)
      }
    }()

    actionHandler?(action)
    delegate?.emptyStateView(self, didTap: action)
    NotificationCenter.default.post(
      name: .fkEmptyStateActionInvoked,
      object: self,
      userInfo: [
        FKEmptyStateNotificationKeys.id: action.id,
        FKEmptyStateNotificationKeys.kind: action.kind.rawValue,
        FKEmptyStateNotificationKeys.payload: action.payload
      ]
    )
  }

  @objc private func handleBackgroundTap() {
    endEditing(true)
    viewTapHandler?()
  }
}

public extension Notification.Name {
  static let fkEmptyStateActionInvoked = Notification.Name("fk.emptyState.actionInvoked")
}

/// Keys used by the `.fkEmptyStateActionInvoked` notification userInfo payload.
///
/// This is a lightweight interop channel for hosts that prefer NotificationCenter routing
/// (e.g. multiple actions handled by a coordinator without wiring closures).
public enum FKEmptyStateNotificationKeys {
  public static let id = "id"
  public static let kind = "kind"
  public static let payload = "payload"
}
