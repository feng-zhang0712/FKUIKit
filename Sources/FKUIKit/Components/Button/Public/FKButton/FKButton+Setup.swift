import UIKit

extension FKButton {
  // MARK: - Setup

  func commonInit() {
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
    impactFeedbackGenerator = UIImpactFeedbackGenerator(style: hapticsConfiguration.impactStyle)
    impactFeedbackGenerator.prepare()
    syncSoundFeedbackResourcesIfNeeded()

    applyAxis()
    applyContentLayout()
    applyTextForCurrentState()
    applyImagesForCurrentState()
    applyCustomContentForCurrentState()
    applyAppearanceForCurrentState()
    applyAccessibilityForCurrentState()

    if let appearances = FKButton.GlobalStyle.defaultAppearances {
      setAppearances(appearances)
    }
    FKButton.GlobalStyle.applyPerNewButton?(self)

    super.contentHorizontalAlignment = .center
    super.contentVerticalAlignment = .center
    applyContentAlignmentLayout()
    syncPointerInteractionIfNeeded()
  }

  // MARK: - Global defaults

  func applyFactoryDefaultsFromGlobalStyle() {
    minimumTapInterval = FKButton.GlobalStyle.minimumTapInterval
    longPressMinimumDuration = FKButton.GlobalStyle.longPressMinimumDuration
    longPressRepeatTickInterval = FKButton.GlobalStyle.longPressRepeatTickInterval
    automaticallyDimsWhenDisabled = FKButton.GlobalStyle.automaticallyDimsWhenDisabled
    disabledDimmingAlpha = FKButton.GlobalStyle.disabledDimmingAlpha
    longPressRecognizer.minimumPressDuration = longPressMinimumDuration
  }
}
