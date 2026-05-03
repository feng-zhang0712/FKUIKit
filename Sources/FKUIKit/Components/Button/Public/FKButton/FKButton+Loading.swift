import UIKit

extension FKButton {
  // MARK: - Loading

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

  // MARK: - Loading overlay (internal views)

  func configureLoadingOverlay() {
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

  func syncLoadingActivityIndicatorColor() {
    loadingIndicator.color = loadingActivityIndicatorColor
  }

  func applyLoadingChromeForCurrentStyle() {
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
}
