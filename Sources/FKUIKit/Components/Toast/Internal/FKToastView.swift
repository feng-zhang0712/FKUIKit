import UIKit

/// Hosts icon/spinner, text stack, optional actions, blur chrome, and gesture recognizers for one request.
final class FKToastView: UIView {
  private let blurEffectView = UIVisualEffectView(effect: nil)
  private let containerStack = UIStackView()
  private let textStack = UIStackView()
  private let iconView = UIImageView()
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let primaryActionButton = UIButton(type: .system)
  private let secondaryActionButton = UIButton(type: .system)

  var onTap: (() -> Void)?
  var onLongPress: (() -> Void)?
  var onPrimaryActionTap: (() -> Void)?
  var onSecondaryActionTap: (() -> Void)?

  init(request: FKToastRequest) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    buildHierarchy()
    applyChrome(configuration: request.configuration)
    bindContent(request: request)
    installInteractions(configuration: request.configuration)
  }

  func updateDisplayedRequest(_ request: FKToastRequest) {
    applyChrome(configuration: request.configuration)
    bindContent(request: request)
    reinstallInteractions(configuration: request.configuration)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  private func buildHierarchy() {
    containerStack.translatesAutoresizingMaskIntoConstraints = false
    containerStack.axis = .horizontal
    containerStack.alignment = .center
    addSubview(containerStack)

    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.alignment = .fill

    NSLayoutConstraint.activate([
      containerStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      containerStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      containerStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      containerStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }

  private func applyChrome(configuration: FKToastConfiguration) {
    directionalLayoutMargins = configuration.contentInsets
    containerStack.spacing = configuration.itemSpacing

    let resolvedBackground = configuration.backgroundColor ?? configuration.style.defaultBackgroundColor
    backgroundColor = resolvedBackground
    installVisualEffectIfNeeded(configuration: configuration)
    preservesSuperviewLayoutMargins = false

    let radius = configuration.cornerRadius ?? (configuration.kind == .snackbar ? 12 : 14)
    layer.cornerRadius = radius
    layer.cornerCurve = .continuous
    blurEffectView.layer.cornerRadius = radius
    blurEffectView.layer.cornerCurve = .continuous

    if configuration.showsShadow {
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOpacity = configuration.shadowOpacity
      layer.shadowRadius = configuration.shadowRadius
      layer.shadowOffset = configuration.shadowOffset
    } else {
      layer.shadowOpacity = 0
    }

    titleLabel.font = configuration.titleFont
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.textColor = configuration.textColor
    titleLabel.numberOfLines = 2

    subtitleLabel.font = configuration.font
    subtitleLabel.adjustsFontForContentSizeCategory = true
    subtitleLabel.textColor = configuration.textColor
    subtitleLabel.numberOfLines = configuration.kind == .snackbar ? 2 : 0
    subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  private func bindContent(request: FKToastRequest) {
    resetContentState()
    let configuration = request.configuration
    if case let .customView(provider) = request.content {
      let customContentView = provider()
      customContentView.translatesAutoresizingMaskIntoConstraints = false
      containerStack.addArrangedSubview(customContentView)
      return
    }

    let shouldShowSpinner = configuration.style == .loading
    if shouldShowSpinner {
      spinner.color = configuration.iconTintColor ?? configuration.textColor
      spinner.startAnimating()
      spinner.setContentHuggingPriority(.required, for: .horizontal)
      containerStack.addArrangedSubview(spinner)
    } else if let resolvedIcon = resolvedIconImage(request: request) {
      iconView.image = resolvedIcon.withRenderingMode(.alwaysTemplate)
      iconView.tintColor = configuration.iconTintColor ?? configuration.textColor
      iconView.preferredSymbolConfiguration = .init(pointSize: 18, weight: .semibold)
      iconView.contentMode = .scaleAspectFit
      iconView.setContentHuggingPriority(.required, for: .horizontal)
      iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
      NSLayoutConstraint.activate([
        iconView.widthAnchor.constraint(equalToConstant: 18),
        iconView.heightAnchor.constraint(equalToConstant: 18),
      ])
      containerStack.addArrangedSubview(iconView)
    }

    switch request.content {
    case let .message(message):
      titleLabel.isHidden = true
      subtitleLabel.text = message
    case let .titleSubtitle(title, subtitle):
      titleLabel.isHidden = false
      titleLabel.text = title
      subtitleLabel.text = subtitle
    case .customView:
      break
    }

    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)
    containerStack.addArrangedSubview(textStack)

    if let action = configuration.action {
      primaryActionButton.setTitle(action.title, for: .normal)
      primaryActionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
      primaryActionButton.setTitleColor(action.titleColor, for: .normal)
      primaryActionButton.accessibilityLabel = action.accessibilityLabel ?? action.title
      primaryActionButton.addTarget(self, action: #selector(handlePrimaryActionTap), for: .touchUpInside)
      containerStack.addArrangedSubview(primaryActionButton)
    }
    if let action = configuration.secondaryAction {
      secondaryActionButton.setTitle(action.title, for: .normal)
      secondaryActionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
      secondaryActionButton.setTitleColor(action.titleColor, for: .normal)
      secondaryActionButton.accessibilityLabel = action.accessibilityLabel ?? action.title
      secondaryActionButton.addTarget(self, action: #selector(handleSecondaryActionTap), for: .touchUpInside)
      containerStack.addArrangedSubview(secondaryActionButton)
    }

    isAccessibilityElement = true
    accessibilityTraits = configuration.kind == .hud ? [.updatesFrequently] : [.staticText]
    accessibilityLabel = titleLabel.isHidden ? subtitleLabel.text : "\(titleLabel.text ?? ""), \(subtitleLabel.text ?? "")"
  }

  private func installVisualEffectIfNeeded(configuration: FKToastConfiguration) {
    guard shouldApplyVisualEffect(configuration: configuration) else {
      blurEffectView.removeFromSuperview()
      blurEffectView.effect = nil
      return
    }
    blurEffectView.translatesAutoresizingMaskIntoConstraints = false
    blurEffectView.clipsToBounds = true
    blurEffectView.alpha = configuration.visualEffectOpacity
    blurEffectView.effect = UIBlurEffect(style: resolvedBlurStyle(configuration: configuration))
    if blurEffectView.superview == nil {
      addSubview(blurEffectView)
      sendSubviewToBack(blurEffectView)
      NSLayoutConstraint.activate([
        blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
        blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
        blurEffectView.topAnchor.constraint(equalTo: topAnchor),
        blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
    // Keep a light tint to preserve text readability while avoiding heavy gray overlays.
    backgroundColor = (configuration.backgroundColor ?? configuration.style.defaultBackgroundColor).withAlphaComponent(0.14)
  }

  private func shouldApplyVisualEffect(configuration: FKToastConfiguration) -> Bool {
    if case .none = configuration.backgroundVisualEffect { return false }
    if configuration.disableVisualEffectInLowPowerMode && ProcessInfo.processInfo.isLowPowerModeEnabled {
      return false
    }
    if configuration.fallbackToSolidColorWhenReduceTransparencyEnabled && UIAccessibility.isReduceTransparencyEnabled {
      return false
    }
    return true
  }

  private func resolvedBlurStyle(configuration: FKToastConfiguration) -> UIBlurEffect.Style {
    switch configuration.backgroundVisualEffect {
    case .none:
      return .regular
    case let .blur(style):
      return style.uiBlurEffectStyle
    case .liquidGlassPreferred:
      if #available(iOS 26.0, *) {
        return .systemThinMaterial
      }
      return .systemMaterial
    }
  }

  private func resolvedIconImage(request: FKToastRequest) -> UIImage? {
    if let explicit = request.icon {
      return explicit
    }
    let symbolSet = request.configuration.symbolSet ?? .init()
    return UIImage(systemName: symbolSet.symbolName(for: request.configuration.style))
  }

  private func resetContentState() {
    for view in containerStack.arrangedSubviews {
      containerStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    spinner.stopAnimating()
    titleLabel.text = nil
    subtitleLabel.text = nil
    primaryActionButton.removeTarget(self, action: #selector(handlePrimaryActionTap), for: .touchUpInside)
    secondaryActionButton.removeTarget(self, action: #selector(handleSecondaryActionTap), for: .touchUpInside)
  }

  private func installInteractions(configuration: FKToastConfiguration) {
    if configuration.tapToDismiss || configuration.action != nil || configuration.secondaryAction != nil {
      let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
      addGestureRecognizer(tap)
    }
    if configuration.longPressToDismiss {
      let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
      addGestureRecognizer(longPress)
    }
  }

  private func reinstallInteractions(configuration: FKToastConfiguration) {
    for recognizer in gestureRecognizers ?? [] {
      if recognizer is UITapGestureRecognizer || recognizer is UILongPressGestureRecognizer {
        removeGestureRecognizer(recognizer)
      }
    }
    installInteractions(configuration: configuration)
  }

  @objc private func handleTap() {
    onTap?()
  }

  @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    onLongPress?()
  }

  @objc private func handlePrimaryActionTap() {
    onPrimaryActionTap?()
  }

  @objc private func handleSecondaryActionTap() {
    onSecondaryActionTap?()
  }
}
