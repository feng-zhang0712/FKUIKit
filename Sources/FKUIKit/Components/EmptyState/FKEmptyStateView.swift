//
// FKEmptyStateView.swift
//
// Visual overlay for loading, empty, and error states. Typically hosted via `UIView.fk_applyEmptyState`.
//

import UIKit

// MARK: - Delegate

/// Delegate for the primary action button (alternative to `actionHandler` closure).
public protocol FKEmptyStateViewDelegate: AnyObject {
  /// Called when the user taps the primary button; fires after `actionHandler` if both are set.
  func emptyStateViewDidTapAction(_ view: FKEmptyStateView)
}

// MARK: - FKEmptyStateView

/// Full-screen overlay for empty, loading, or error UI.
///
/// Prefer adding to `UIViewController.view` or a `UIScrollView` subview — **not** `UITableView.backgroundView`, so refresh controls remain visible above table backgrounds.
///
/// Touch handling: the view fills the host bounds and intercepts touches; `UIGestureRecognizerDelegate` avoids stealing taps from `UIControl` subclasses (e.g. the action button). Optional dimming uses `blockingOverlayAlpha`.
public final class FKEmptyStateView: UIView, UIGestureRecognizerDelegate {

  // MARK: Public

  /// Optional delegate for button taps.
  public weak var delegate: FKEmptyStateViewDelegate?
  /// Closure invoked when the primary button is tapped; use `[weak self]` at the call site to avoid cycles.
  public var actionHandler: FKVoidHandler?
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
  private let actionButton = UIButton(type: .system)
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
    if animated {
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

    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

    descriptionLabel.numberOfLines = 0
    descriptionLabel.textAlignment = .center

    actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
    actionButton.titleLabel?.numberOfLines = 1

    loadingIndicator.hidesWhenStopped = true

    keyboardDismissTap.addTarget(self, action: #selector(handleBackgroundTap))
    keyboardDismissTap.cancelsTouchesInView = false
    keyboardDismissTap.delegate = self
    addGestureRecognizer(keyboardDismissTap)

    containerMaxWidthConstraint = containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
    containerMaxWidthConstraint?.isActive = true

    let centerY = containerView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
    centerY.priority = UILayoutPriority(750)
    centerY.isActive = true

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

    switch model.phase {
    case .content:
      break
    case .loading:
      applyLoadingPhase(model: model)
    case .empty, .error:
      applyContentPhase(model: model)
    }

    keyboardDismissTap.isEnabled = model.supportsTapToDismissKeyboard
    keyboardBottomConstraint?.isActive = model.adjustsPositionForKeyboard
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

    var buttonConfig = UIButton.Configuration.filled()
    buttonConfig.title = model.buttonStyle.title
    buttonConfig.baseBackgroundColor = model.buttonStyle.backgroundColor
    buttonConfig.baseForegroundColor = model.buttonStyle.titleColor
    buttonConfig.cornerStyle = .fixed
    buttonConfig.contentInsets = NSDirectionalEdgeInsets(
      top: model.buttonStyle.contentInsets.top,
      leading: model.buttonStyle.contentInsets.left,
      bottom: model.buttonStyle.contentInsets.bottom,
      trailing: model.buttonStyle.contentInsets.right
    )
    actionButton.configuration = buttonConfig
    actionButton.layer.cornerRadius = model.buttonStyle.cornerRadius
    actionButton.layer.masksToBounds = true
    actionButton.layer.borderWidth = model.buttonStyle.borderWidth
    actionButton.layer.borderColor = model.buttonStyle.borderColor?.cgColor
    actionButton.isHidden = true

    rebuildStack(orderedViews: [loadingIndicator, titleLabel, descriptionLabel, actionButton])
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

    var effectiveButtonHidden = model.isButtonHidden || model.buttonStyle.title?.isEmpty != false
    var buttonTitle = model.buttonStyle.title
    if model.phase == .error {
      effectiveButtonHidden = false
      if buttonTitle?.isEmpty != false {
        buttonTitle = FKEmptyStateModel.defaultRetryButtonTitle
      }
    }

    var buttonConfig = UIButton.Configuration.filled()
    buttonConfig.title = buttonTitle
    buttonConfig.baseBackgroundColor = model.buttonStyle.backgroundColor
    buttonConfig.baseForegroundColor = model.buttonStyle.titleColor
    buttonConfig.cornerStyle = .fixed
    buttonConfig.contentInsets = NSDirectionalEdgeInsets(
      top: model.buttonStyle.contentInsets.top,
      leading: model.buttonStyle.contentInsets.left,
      bottom: model.buttonStyle.contentInsets.bottom,
      trailing: model.buttonStyle.contentInsets.right
    )
    actionButton.configuration = buttonConfig
    actionButton.layer.cornerRadius = model.buttonStyle.cornerRadius
    actionButton.layer.masksToBounds = true
    actionButton.layer.borderWidth = model.buttonStyle.borderWidth
    actionButton.layer.borderColor = model.buttonStyle.borderColor?.cgColor
    actionButton.titleLabel?.font = model.buttonStyle.font
    actionButton.isHidden = effectiveButtonHidden
    actionButton.isEnabled = true

    rebuildStack(orderedViews: contentBlocks(model: model))
  }

  /// Builds stack order for empty/error based on `customAccessoryPlacement`.
  private func contentBlocks(model: FKEmptyStateModel) -> [UIView] {
    let imageBlock = imageView
    let customBlock = customAccessoryContainer
    switch model.customAccessoryPlacement {
    case .replaceImage:
      return [customBlock, titleLabel, descriptionLabel, actionButton]
    case .aboveImage:
      return [customBlock, imageBlock, titleLabel, descriptionLabel, actionButton]
    case .belowImage:
      return [imageBlock, customBlock, titleLabel, descriptionLabel, actionButton]
    case .belowDescription:
      return [imageBlock, titleLabel, descriptionLabel, customBlock, actionButton]
    }
  }

  private func rebuildStack(orderedViews: [UIView]) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    for v in orderedViews {
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

  // MARK: UIGestureRecognizerDelegate

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if touch.view is UIControl { return false }
    return true
  }

  // MARK: Actions

  @objc private func handleActionTap() {
    actionHandler?()
    delegate?.emptyStateViewDidTapAction(self)
  }

  @objc private func handleBackgroundTap() {
    endEditing(true)
  }
}
