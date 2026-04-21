import UIKit

final class FKTopNotificationCardView: UIView {
  private let stackView = UIStackView()
  private let iconView = UIImageView()
  private let textStack = UIStackView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let actionButton = UIButton(type: .system)
  private let progressView = UIProgressView(progressViewStyle: .default)

  var onTap: (() -> Void)?
  var onActionTap: (() -> Void)?
  var onCloseBySwipe: (() -> Void)?

  init(
    title: String?,
    subtitle: String?,
    icon: UIImage?,
    customContentView: UIView?,
    progress: Float?,
    configuration: FKTopNotificationConfiguration
  ) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    setupAppearance(configuration: configuration)
    setupHierarchy()
    bindContent(
      title: title,
      subtitle: subtitle,
      icon: icon,
      customContentView: customContentView,
      progress: progress,
      configuration: configuration
    )
    installInteraction(configuration: configuration)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  func updateProgress(_ progress: Float) {
    // Ignore updates when this card was not configured in progress mode.
    guard !progressView.isHidden else { return }
    // Clamp to 0...1 to keep progress value valid.
    progressView.setProgress(min(max(progress, 0), 1), animated: true)
  }

  private func setupAppearance(configuration: FKTopNotificationConfiguration) {
    // Resolve visual token values from style + per-request overrides.
    backgroundColor = configuration.backgroundColor ?? configuration.style.defaultBackgroundColor
    directionalLayoutMargins = configuration.contentInsets
    layer.cornerRadius = configuration.cornerRadius
    layer.cornerCurve = .continuous

    if configuration.showsShadow {
      // Enable card shadow for elevation against complex backgrounds.
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOpacity = configuration.shadowOpacity
      layer.shadowRadius = configuration.shadowRadius
      layer.shadowOffset = configuration.shadowOffset
    }
  }

  private func setupHierarchy() {
    // Main horizontal stack contains icon, text block, and optional action button.
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.alignment = .top
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }

  private func bindContent(
    title: String?,
    subtitle: String?,
    icon: UIImage?,
    customContentView: UIView?,
    progress: Float?,
    configuration: FKTopNotificationConfiguration
  ) {
    stackView.spacing = configuration.itemSpacing

    if let customContentView {
      // Custom view path bypasses default title/subtitle/icon rendering.
      customContentView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(customContentView)
      return
    }

    let resolvedIcon = icon ?? UIImage(systemName: configuration.style.defaultSymbolName)
    if let resolvedIcon {
      // Render icon as template image so tint can follow current configuration.
      iconView.image = resolvedIcon.withRenderingMode(.alwaysTemplate)
      iconView.tintColor = configuration.iconTintColor ?? configuration.textColor
      iconView.preferredSymbolConfiguration = .init(pointSize: 17, weight: .semibold)
      iconView.setContentHuggingPriority(.required, for: .horizontal)
      iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
      NSLayoutConstraint.activate([
        iconView.widthAnchor.constraint(equalToConstant: 18),
        iconView.heightAnchor.constraint(equalToConstant: 18),
      ])
      stackView.addArrangedSubview(iconView)
    }

    textStack.axis = .vertical
    textStack.spacing = 3
    textStack.alignment = .fill
    textStack.distribution = .fill
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    let resolvedTitle = title ?? ""
    // Keep title as non-optional to avoid layout ambiguity.
    titleLabel.text = resolvedTitle
    titleLabel.font = configuration.font
    titleLabel.textColor = configuration.textColor
    titleLabel.numberOfLines = 2
    titleLabel.adjustsFontForContentSizeCategory = true
    textStack.addArrangedSubview(titleLabel)

    if let subtitle, !subtitle.isEmpty {
      // Subtitle is optional and only added when non-empty.
      subtitleLabel.text = subtitle
      subtitleLabel.font = configuration.subtitleFont
      subtitleLabel.textColor = configuration.subtitleColor
      subtitleLabel.numberOfLines = 3
      subtitleLabel.adjustsFontForContentSizeCategory = true
      textStack.addArrangedSubview(subtitleLabel)
    }

    if let progress {
      // Progress bar is rendered only in progress-enabled requests.
      progressView.progress = min(max(progress, 0), 1)
      progressView.trackTintColor = configuration.progressTrackColor ?? UIColor(white: 1, alpha: 0.25)
      progressView.progressTintColor = configuration.progressTintColor ?? configuration.textColor
      progressView.layer.cornerRadius = 2
      progressView.clipsToBounds = true
      textStack.addArrangedSubview(progressView)
    } else {
      progressView.isHidden = true
    }

    stackView.addArrangedSubview(textStack)

    if let action = configuration.action {
      // Action button is appended at trailing side when configured.
      actionButton.setTitle(action.title, for: .normal)
      actionButton.setTitleColor(action.titleColor, for: .normal)
      actionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
      actionButton.contentEdgeInsets = .init(top: 4, left: 6, bottom: 4, right: 6)
      actionButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
      actionButton.setContentHuggingPriority(.required, for: .horizontal)
      actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
      stackView.addArrangedSubview(actionButton)
    }
  }

  private func installInteraction(configuration: FKTopNotificationConfiguration) {
    if configuration.tapToDismiss || configuration.action != nil {
      // Body tap forwards to center; dismiss behavior is decided by configuration.
      let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
      addGestureRecognizer(tap)
    }
    if configuration.swipeToDismiss {
      // Pan recognizer enables upward swipe dismissal gesture.
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      addGestureRecognizer(pan)
    }
  }

  @objc private func handleTap() {
    onTap?()
  }

  @objc private func actionTap() {
    onActionTap?()
  }

  @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
    switch pan.state {
    case .changed:
      let translation = pan.translation(in: superview)
      if translation.y < 0 {
        // Follow the finger only for upward movement and gradually reduce alpha.
        transform = CGAffineTransform(translationX: 0, y: translation.y)
        alpha = max(0.45, 1 + translation.y / 200)
      }
    case .ended, .cancelled, .failed:
      let translation = pan.translation(in: superview).y
      let velocity = pan.velocity(in: superview).y
      // Dismiss when translation or velocity reaches threshold.
      if translation < -32 || velocity < -500 {
        onCloseBySwipe?()
      } else {
        // Restore visual state when the swipe does not qualify for dismissal.
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
          self.transform = .identity
          self.alpha = 1
        }
      }
    default:
      break
    }
  }
}
