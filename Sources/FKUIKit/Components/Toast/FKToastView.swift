import UIKit

final class FKToastView: UIView {
  private let stackView = UIStackView()
  private let iconView = UIImageView()
  private let messageLabel = UILabel()
  private let actionButton = UIButton(type: .system)

  // Called when the container is tapped (dismiss semantics handled by the caller).
  var onTap: (() -> Void)?
  // Called when the action button is tapped.
  var onActionTap: (() -> Void)?

  init(
    text: String,
    icon: UIImage?,
    customContentView: UIView?,
    configuration: FKToastConfiguration
  ) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    setupView(configuration: configuration)
    bindContent(text: text, icon: icon, customContentView: customContentView, configuration: configuration)
    installInteractions(configuration: configuration)
  }

  required init?(coder: NSCoder) {
    return nil
  }

  private func setupView(configuration: FKToastConfiguration) {
    // Resolve colors and layout metrics. Most UI properties are controlled by configuration
    // so callers can override style per message.
    let resolvedBackground = configuration.backgroundColor ?? configuration.style.defaultBackgroundColor
    backgroundColor = resolvedBackground
    directionalLayoutMargins = configuration.contentInsets
    preservesSuperviewLayoutMargins = false

    let radius = configuration.cornerRadius ?? (configuration.kind == .snackbar ? 12 : 14)
    layer.cornerRadius = radius
    layer.cornerCurve = .continuous

    if configuration.showsShadow {
      // Shadow defaults match iOS overlay cards while remaining subtle.
      layer.shadowColor = UIColor.black.cgColor
      layer.shadowOpacity = configuration.shadowOpacity
      layer.shadowRadius = configuration.shadowRadius
      layer.shadowOffset = configuration.shadowOffset
    } else {
      layer.shadowOpacity = 0
    }

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.spacing = configuration.itemSpacing
    stackView.alignment = .center
    stackView.distribution = .fill
    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }

  private func bindContent(
    text: String,
    icon: UIImage?,
    customContentView: UIView?,
    configuration: FKToastConfiguration
  ) {
    if let customContentView {
      // Custom content bypasses default icon/label/action composition.
      customContentView.translatesAutoresizingMaskIntoConstraints = false
      stackView.addArrangedSubview(customContentView)
      return
    }

    let resolvedIcon = icon ?? UIImage(systemName: configuration.style.defaultSymbolName)
    if let resolvedIcon {
      // Use template rendering so tint is driven by configuration.
      iconView.image = resolvedIcon.withRenderingMode(.alwaysTemplate)
      iconView.tintColor = configuration.iconTintColor ?? configuration.textColor
      iconView.preferredSymbolConfiguration = .init(pointSize: 17, weight: .semibold)
      iconView.contentMode = .scaleAspectFit
      iconView.setContentHuggingPriority(.required, for: .horizontal)
      iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
      NSLayoutConstraint.activate([
        iconView.widthAnchor.constraint(equalToConstant: 18),
        iconView.heightAnchor.constraint(equalToConstant: 18),
      ])
      stackView.addArrangedSubview(iconView)
    }

    messageLabel.text = text
    messageLabel.font = configuration.font
    messageLabel.textColor = configuration.textColor
    // Snackbars are typically short; keep at most two lines to preserve layout stability.
    messageLabel.numberOfLines = configuration.kind == .snackbar ? 2 : 0
    messageLabel.lineBreakMode = .byWordWrapping
    messageLabel.textAlignment = .natural
    messageLabel.adjustsFontForContentSizeCategory = true
    stackView.addArrangedSubview(messageLabel)

    if let action = configuration.action {
      // Action is optional; handler invocation is owned by FKToastCenter.
      actionButton.setTitle(action.title, for: .normal)
      actionButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
      actionButton.setTitleColor(action.titleColor, for: .normal)
      actionButton.contentEdgeInsets = .init(top: 4, left: 6, bottom: 4, right: 6)
      actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
      actionButton.setContentHuggingPriority(.required, for: .horizontal)
      actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
      stackView.addArrangedSubview(actionButton)
    }
  }

  private func installInteractions(configuration: FKToastConfiguration) {
    if configuration.tapToDismiss || configuration.action != nil {
      // Install a tap recognizer even if tap-to-dismiss is off when an action exists, so the
      // container can still forward taps in a consistent way (caller decides behavior).
      let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
      addGestureRecognizer(tap)
    }
  }

  @objc private func handleTap() {
    onTap?()
  }

  @objc private func handleActionTap() {
    onActionTap?()
  }
}
