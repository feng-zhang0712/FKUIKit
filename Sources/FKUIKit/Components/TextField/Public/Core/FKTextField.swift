import UIKit

/// Formatted `UITextField` subclass: filtering, raw/display formatting, validation, and styling.
///
/// Configure with ``FKTextFieldInputRule`` and ``FKTextFieldConfiguration``; plug in custom types via
/// ``FKTextFieldFormatting`` and ``FKTextFieldValidating``.
@MainActor
public final class FKTextField: UITextField, FKTextFieldConfigurable {
  /// Current full configuration.
  public private(set) var configuration: FKTextFieldConfiguration

  /// Current validation result.
  public private(set) var validationResult: FKTextFieldValidationResult = .valid
  /// Current resolved status.
  public private(set) var status: FKTextFieldStatus = .normal

  /// Closure called on each editing changed event.
  public var onEditingChanged: ((String, String) -> Void)?
  /// Closure called when editing begins.
  public var onDidBeginEditing: (() -> Void)?
  /// Closure called when editing ends.
  public var onDidEndEditing: (() -> Void)?
  /// Closure called when return/submit is triggered.
  public var onDidSubmit: ((String) -> Void)?
  /// Closure called when validation fails.
  public var onDidFailValidation: ((FKTextFieldValidationResult) -> Void)?
  /// Closure called when formatter output is produced.
  public var onFormattedResult: ((FKTextFieldFormattingResult) -> Void)?
  /// Closure called when validation result changes.
  public var onValidationResult: ((FKTextFieldValidationResult) -> Void)?
  /// Closure called when fixed-length input is completed.
  public var onInputCompleted: ((String) -> Void)?
  /// Closure called when password visibility is toggled.
  ///
  /// The value indicates whether the password is currently visible.
  public var onPasswordVisibilityToggled: ((Bool) -> Void)?
  /// Closure called when text is cleared.
  public var onDidClear: (() -> Void)?

  /// Raw text value without visual separators.
  ///
  /// Use this value for storage and API submission.
  public var rawText: String {
    textState.rawText
  }

  /// Controls whether password text is visible.
  ///
  /// This property is meaningful only when `configuration.inputRule.formatType == .password`.
  public var isPasswordVisible: Bool = false {
    didSet { applySecureTextEntry() }
  }

  /// External delegate receiver for app-level behaviors.
  ///
  /// `FKTextField` sets itself as `delegate` to intercept formatting. Use this property
  /// if you still need delegate callbacks in your app.
  public weak var forwardingDelegate: UITextFieldDelegate?

  /// Next field used by return-key focus chaining.
  ///
  /// When `configuration.inputRule.returnKeyBehavior == .next`, the field will attempt to move
  /// focus to this next field; if `nil`, it resigns first responder.
  public weak var nextTextField: FKTextField?

  /// Formatter implementation used to produce raw/formatted output.
  private let formatter: FKTextFieldFormatting
  /// Validator implementation used to produce validity and optional messages.
  private let validator: FKTextFieldValidating
  /// Optional asynchronous validator for server-backed checks.
  private var asyncValidator: FKTextFieldAsyncValidating?
  /// Debounce work item for callback coalescing.
  private var debounceTask: DispatchWorkItem?
  /// Last accepted input timestamp for anti-burst protection.
  private var lastInputTime: CFAbsoluteTime = 0
  /// Internal state snapshot (raw/formatted/error) for current value.
  private var textState = FKTextFieldState()
  /// Built-in password visibility toggle.
  private lazy var passwordToggleButton = UIButton(type: .system)
  /// Built-in clear button rendered in the trailing accessory container.
  private lazy var clearButton = UIButton(type: .system)
  /// Size constraint for clear button touch target.
  private var clearButtonWidthConstraint: NSLayoutConstraint?
  /// Size constraint for clear button touch target.
  private var clearButtonHeightConstraint: NSLayoutConstraint?
  /// Built-in counter label rendered in the trailing accessory container.
  private lazy var counterLabel = UILabel()
  /// Internal trailing container used as `rightView` to host multiple accessories.
  private let trailingAccessoryStack = UIStackView()
  /// Inline error label rendered below the text area when enabled.
  private lazy var inlineErrorLabel = UILabel()
  /// Floating title label rendered above text content.
  private lazy var floatingTitleLabel = UILabel()
  /// Latest async validation task.
  private var asyncValidationTask: Task<Void, Never>?
  /// Validation debounce task.
  private var validationDebounceTask: DispatchWorkItem?
  /// Incrementing token for async validation race handling.
  private var asyncValidationToken: Int = 0
  /// External forced status override.
  private var forcedStatus: FKTextFieldStatus?
  /// Underline layer used when `configuration.decoration.mode == .underline`.
  private let underlineLayer = CALayer()
  /// Size constraint for password toggle button touch target.
  private var passwordButtonWidthConstraint: NSLayoutConstraint?
  /// Size constraint for password toggle button touch target.
  private var passwordButtonHeightConstraint: NSLayoutConstraint?

  /// Creates a text field with custom formatter and validator.
  public init(
    configuration: FKTextFieldConfiguration,
    formatter: FKTextFieldFormatting = FKTextFieldDefaultFormatter(),
    validator: FKTextFieldValidating = FKTextFieldDefaultValidator(),
    asyncValidator: FKTextFieldAsyncValidating? = nil
  ) {
    self.configuration = configuration
    self.formatter = formatter
    self.validator = validator
    self.asyncValidator = asyncValidator
    super.init(frame: .zero)
    commonInit()
  }

  /// Creates a text field using global style defaults.
  public convenience init(inputRule: FKTextFieldInputRule) {
    let configuration = FKTextFieldConfiguration(
      inputRule: inputRule,
      style: FKTextFieldManager.shared.defaultStyle,
      localization: FKTextFieldManager.shared.defaultLocalization
    )
    self.init(configuration: configuration)
  }

  /// Interface Builder initializer.
  public required init?(coder: NSCoder) {
    configuration = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(formatType: .alphaNumeric),
      style: FKTextFieldManager.shared.defaultStyle,
      localization: FKTextFieldManager.shared.defaultLocalization
    )
    formatter = FKTextFieldDefaultFormatter()
    validator = FKTextFieldDefaultValidator()
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a full configuration.
  public func configure(_ configuration: FKTextFieldConfiguration) {
    self.configuration = configuration
    applyConfiguration()
    reformatCurrentText()
  }

  /// Updates input rule only.
  public func updateInputRule(_ rule: FKTextFieldInputRule) {
    configuration.inputRule = rule
    applyConfiguration()
    reformatCurrentText()
  }

  /// Sets an explicit error state and message.
  public func setError(message: String?) {
    textState.errorMessage = message
    configuration.messages.error = message
    configuration.messages.success = nil
    forcedStatus = (message == nil ? nil : .error)
    updateInlineErrorLabel()
    applyStateStyle()
  }

  /// Sets success message and enters success state.
  public func setSuccess(message: String?) {
    configuration.messages.success = message
    forcedStatus = .success
    textState.errorMessage = nil
    validationResult = .valid
    updateInlineErrorLabel()
    applyStateStyle()
  }

  /// Sets helper message.
  public func setHelper(message: String?) {
    configuration.messages.helper = message
    updateInlineErrorLabel()
  }

  /// Clears current text and state.
  public func clear() {
    asyncValidationTask?.cancel()
    validationDebounceTask?.cancel()
    textState = FKTextFieldState()
    text = nil
    validationResult = .valid
    forcedStatus = nil
    onEditingChanged?("", "")
    onValidationResult?(.valid)
    updateFloatingTitleVisibility()
    updateInlineErrorLabel()
    applyStateStyle()
  }

  /// Forces an external status and optional message.
  ///
  /// - Important: Pass `nil` status through `resetForcedStatus()` to resume automatic status resolution.
  public func forceStatus(_ status: FKTextFieldStatus, message: String? = nil) {
    forcedStatus = status
    if status == .error {
      textState.errorMessage = message ?? configuration.messages.error
    } else if status == .success {
      configuration.messages.success = message ?? configuration.messages.success
      textState.errorMessage = nil
    }
    updateInlineErrorLabel()
    applyStateStyle()
  }

  /// Clears forced status override and returns to automatic state resolution.
  public func resetForcedStatus() {
    forcedStatus = nil
    applyStateStyle()
  }

  /// Validates the current value immediately and refreshes messages and visual state.
  ///
  /// Use this for form-level submit when individual fields use `.onBlur` or `.onChange` triggers
  /// and you still need a single synchronous validation pass across all fields.
  /// Async validation, if configured, runs after sync validation when the sync result is valid.
  public func validateNow() {
    validationDebounceTask?.cancel()
    asyncValidationTask?.cancel()
    let result = FKTextFieldFormattingResult(
      rawText: textState.rawText,
      formattedText: textState.formattedText,
      isTruncated: false,
      removedIllegalCharacters: false
    )
    applySyncValidation(for: result)
    updateInlineErrorLabel()
    applyStateStyle()
  }

  /// Installs or replaces async validator at runtime.
  public func setAsyncValidator(_ validator: FKTextFieldAsyncValidating?) {
    asyncValidator = validator
  }

  /// Connects the receiver to the next field for return-key focus chaining.
  ///
  /// - Parameter next: The next field to focus when return is pressed.
  public func linkNext(_ next: FKTextField?) {
    nextTextField = next
    // Keep return key UX consistent with chaining intent.
    if next != nil, configuration.inputRule.returnKeyBehavior == .system {
      configuration.inputRule.returnKeyBehavior = .next
    }
  }

  /// Triggers a shake animation for invalid input feedback.
  ///
  /// Call this when you want an explicit visual hint (e.g. after a submit action).
  public func shakeForValidationFailure() {
    fk_shake()
  }
}

private extension FKTextField {
  /// Applies baseline UIKit defaults and installs internal observers/targets.
  func commonInit() {
    delegate = self
    addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
    addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    autocorrectionType = .no
    spellCheckingType = .no
    smartDashesType = .no
    smartQuotesType = .no
    smartInsertDeleteType = .no
    // Prefer the custom clear button when enabled to avoid duplicated affordances.
    clearButtonMode = configuration.accessories.clearButton.isEnabled ? .never : .whileEditing
    adjustsFontForContentSizeCategory = true
    setupInlineViewsIfNeeded()
    setupDecorationLayers()
    setupTrailingAccessoryContainer()
    applyConfiguration()
    updateAccessibilityConfiguration()
  }

  /// Installs decoration layers (e.g. underline) once.
  func setupDecorationLayers() {
    underlineLayer.isHidden = true
    layer.addSublayer(underlineLayer)
  }

  /// Installs the trailing accessory container once.
  func setupTrailingAccessoryContainer() {
    trailingAccessoryStack.axis = .horizontal
    trailingAccessoryStack.alignment = .center
    trailingAccessoryStack.distribution = .fill
    trailingAccessoryStack.spacing = configuration.accessories.spacing
    trailingAccessoryStack.isLayoutMarginsRelativeArrangement = true
    trailingAccessoryStack.layoutMargins = UIEdgeInsets(
      top: 0,
      left: configuration.accessories.horizontalPadding,
      bottom: 0,
      right: configuration.accessories.horizontalPadding
    )
    setupAccessoryButtonSizingIfNeeded()
    // Use rightView so the system continues to provide a stable text rect.
    rightView = trailingAccessoryStack
    rightViewMode = .never
  }

  /// Applies the current configuration to UIKit properties and internal subviews.
  func applyConfiguration() {
    let formatType = configuration.inputRule.formatType
    let traits = configuration.textInputTraits
    keyboardType = formatType.keyboardType
    textContentType = traits.textContentType ?? Self.inferredTextContentType(for: formatType)
    returnKeyType = traits.returnKeyType ?? Self.inferredReturnKeyType(for: configuration.inputRule.returnKeyBehavior)
    autocapitalizationType = traits.autocapitalizationType ?? Self.inferredAutocapitalization(for: formatType)
    keyboardAppearance = traits.keyboardAppearance ?? .default
    switch formatType {
    case .password:
      passwordRules = traits.passwordRules
    default:
      passwordRules = nil
    }
    font = configuration.style.font
    textColor = configuration.style.textColor
    borderStyle = .none
    // Prefer the custom clear button when enabled to avoid duplicated affordances.
    clearButtonMode = configuration.accessories.clearButton.isEnabled ? .never : .whileEditing
    updateAccessoryButtonSizing()
    applyPlaceholder()
    floatingTitleLabel.text = configuration.floatingTitle
    floatingTitleLabel.font = configuration.style.floatingTitleFont
    floatingTitleLabel.textColor = configuration.style.floatingTitleColor
    floatingTitleLabel.adjustsFontForContentSizeCategory = true
    rebuildTrailingAccessories()
    applySecureTextEntry()
    applyStateStyle()
    updateFloatingTitleVisibility()
    updateInlineErrorLabel()
    updateAccessibilityConfiguration()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  /// Installs inline subviews used for inline messaging.
  func setupInlineViewsIfNeeded() {
    floatingTitleLabel.isHidden = true
    floatingTitleLabel.numberOfLines = 1
    addSubview(floatingTitleLabel)
    inlineErrorLabel.isHidden = true
    inlineErrorLabel.numberOfLines = 0
    addSubview(inlineErrorLabel)
  }

  /// Applies placeholder content and styling.
  func applyPlaceholder() {
    if let attributedPlaceholder = configuration.attributedPlaceholder {
      self.attributedPlaceholder = attributedPlaceholder
      return
    }
    placeholder = configuration.placeholder
    guard let placeholder else { return }
    attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: [
        .foregroundColor: configuration.style.placeholderColor,
        .font: configuration.style.placeholderFont,
      ]
    )
  }

  /// Rebuilds the trailing accessory container based on current configuration and format type.
  func rebuildTrailingAccessories() {
    trailingAccessoryStack.arrangedSubviews.forEach { view in
      trailingAccessoryStack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    trailingAccessoryStack.spacing = configuration.accessories.spacing
    trailingAccessoryStack.layoutMargins = UIEdgeInsets(
      top: 0,
      left: configuration.accessories.horizontalPadding,
      bottom: 0,
      right: configuration.accessories.horizontalPadding
    )

    // Clear button.
    if configuration.accessories.clearButton.isEnabled {
      clearButton.setImage(
        configuredAccessoryImage(configuration.accessories.clearButton.image ?? UIImage(systemName: "xmark.circle.fill")),
        for: .normal
      )
      clearButton.accessibilityLabel = configuration.accessories.clearButton.accessibilityLabel.isEmpty
        ? configuration.localization.clearButtonLabel
        : configuration.accessories.clearButton.accessibilityLabel
      clearButton.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
      trailingAccessoryStack.addArrangedSubview(clearButton)
    }

    // Counter.
    if configuration.counter.isEnabled {
      counterLabel.font = configuration.counter.font
      counterLabel.textColor = configuration.counter.color
      counterLabel.textAlignment = .right
      trailingAccessoryStack.addArrangedSubview(counterLabel)
    }

    // Password toggle (password mode only).
    if case .password = configuration.inputRule.formatType, configuration.accessories.passwordToggle.isEnabled {
      passwordToggleButton.setImage(
        configuredAccessoryImage(configuration.accessories.passwordToggle.hiddenImage ?? UIImage(systemName: "eye.slash")),
        for: .normal
      )
      passwordToggleButton.accessibilityLabel = configuration.localization.passwordHiddenLabel
      passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisible), for: .touchUpInside)
      trailingAccessoryStack.addArrangedSubview(passwordToggleButton)
    }

    // When there are no accessories, do not occupy `rightView`.
    let hasAccessories = !trailingAccessoryStack.arrangedSubviews.isEmpty
    rightViewMode = hasAccessories ? .whileEditing : .never
    applyAccessoryTintColor(using: currentStateStyle())
    setNeedsLayout()
  }

  /// Applies secure text entry based on password mode and `isPasswordVisible`.
  func applySecureTextEntry() {
    guard case .password = configuration.inputRule.formatType else {
      isSecureTextEntry = false
      return
    }
    isSecureTextEntry = !isPasswordVisible
    let image = isPasswordVisible
      ? (configuration.accessories.passwordToggle.visibleImage ?? UIImage(systemName: "eye"))
      : (configuration.accessories.passwordToggle.hiddenImage ?? UIImage(systemName: "eye.slash"))
    passwordToggleButton.setImage(configuredAccessoryImage(image), for: .normal)
    passwordToggleButton.accessibilityLabel = isPasswordVisible
      ? configuration.localization.passwordVisibleLabel
      : configuration.localization.passwordHiddenLabel
  }

  /// Applies the appropriate visual style for normal/focused/error state.
  func applyStateStyle() {
    status = resolvedStatus()
    let stateStyle = currentStateStyle()

    switch configuration.decoration.mode {
    case .border:
      underlineLayer.isHidden = true
      layer.cornerRadius = stateStyle.cornerRadius
      layer.borderWidth = stateStyle.borderWidth
      layer.borderColor = stateStyle.borderColor.cgColor
    case let .underline(thickness, _):
      layer.cornerRadius = stateStyle.cornerRadius
      layer.borderWidth = 0
      layer.borderColor = UIColor.clear.cgColor
      underlineLayer.isHidden = false
      underlineLayer.backgroundColor = stateStyle.borderColor.cgColor
      underlineLayer.cornerRadius = thickness / 2
    }

    let applyLayerStyling = {
      self.layer.backgroundColor = stateStyle.backgroundColor.cgColor
      self.layer.shadowColor = stateStyle.shadowColor?.cgColor
      self.layer.shadowOpacity = stateStyle.shadowOpacity
      self.layer.shadowOffset = stateStyle.shadowOffset
      self.layer.shadowRadius = stateStyle.shadowRadius
    }
    if configuration.motion.isEnabled, !UIAccessibility.isReduceMotionEnabled {
      CATransaction.begin()
      CATransaction.setAnimationDuration(configuration.motion.transitionDuration)
      applyLayerStyling()
      CATransaction.commit()
    } else {
      applyLayerStyling()
    }
    applyAccessoryTintColor(using: stateStyle)
  }

  func resolvedStatus() -> FKTextFieldStatus {
    if let forcedStatus {
      return forcedStatus
    }
    if configuration.isReadOnly {
      return .readOnly
    }
    if !isEnabled {
      return .disabled
    }
    if textState.errorMessage != nil || !validationResult.isValid {
      return .error
    }
    if let success = configuration.messages.success, !success.isEmpty {
      return .success
    }
    if isFirstResponder {
      return .focused
    }
    if !textState.rawText.isEmpty {
      return .filled
    }
    return .normal
  }

  func currentStateStyle() -> FKTextFieldStateStyle {
    switch resolvedStatus() {
    case .normal:
      return configuration.style.normal
    case .focused:
      return configuration.style.focused
    case .filled:
      return configuration.style.filled
    case .error:
      return configuration.style.error
    case .success:
      return configuration.style.success
    case .disabled:
      return configuration.style.disabled
    case .readOnly:
      return configuration.style.readOnly
    }
  }

  func applyAccessoryTintColor(using stateStyle: FKTextFieldStateStyle) {
    let color: UIColor
    switch configuration.accessories.tintBehavior {
    case .fixed:
      color = configuration.style.placeholderColor
    case .followsBorderState:
      color = stateStyle.borderColor
    }
    clearButton.tintColor = color
    passwordToggleButton.tintColor = color
  }

  func configuredAccessoryImage(_ image: UIImage?) -> UIImage? {
    guard let image else { return nil }
    let symbolConfiguration = UIImage.SymbolConfiguration(
      pointSize: configuration.accessories.iconSize,
      weight: .regular
    )
    return image.applyingSymbolConfiguration(symbolConfiguration) ?? image
  }

  func setupAccessoryButtonSizingIfNeeded() {
    guard clearButtonWidthConstraint == nil, clearButtonHeightConstraint == nil,
          passwordButtonWidthConstraint == nil, passwordButtonHeightConstraint == nil else {
      return
    }
    clearButton.translatesAutoresizingMaskIntoConstraints = false
    passwordToggleButton.translatesAutoresizingMaskIntoConstraints = false
    clearButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    passwordToggleButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

    let side = max(configuration.accessibility.minimumHitTarget, configuration.accessories.iconSize + 8)
    clearButtonWidthConstraint = clearButton.widthAnchor.constraint(equalToConstant: side)
    clearButtonHeightConstraint = clearButton.heightAnchor.constraint(equalToConstant: side)
    passwordButtonWidthConstraint = passwordToggleButton.widthAnchor.constraint(equalToConstant: side)
    passwordButtonHeightConstraint = passwordToggleButton.heightAnchor.constraint(equalToConstant: side)

    clearButtonWidthConstraint?.isActive = true
    clearButtonHeightConstraint?.isActive = true
    passwordButtonWidthConstraint?.isActive = true
    passwordButtonHeightConstraint?.isActive = true
  }

  func updateAccessoryButtonSizing() {
    let side = max(configuration.accessibility.minimumHitTarget, configuration.accessories.iconSize + 8)
    clearButtonWidthConstraint?.constant = side
    clearButtonHeightConstraint?.constant = side
    passwordButtonWidthConstraint?.constant = side
    passwordButtonHeightConstraint?.constant = side
  }

  func restoreCursor(rawOffset: Int) {
    guard isFirstResponder else { return }
    let formatted = textState.formattedText
    var resolvedOffset = formatted.count
    for idx in 0...formatted.count {
      let prefix = String(formatted.prefix(idx))
      let mapped = formatter.format(text: prefix, rule: configuration.inputRule).rawText.count
      if mapped >= rawOffset {
        resolvedOffset = idx
        break
      }
    }
    if let position = position(from: beginningOfDocument, offset: resolvedOffset) {
      selectedTextRange = textRange(from: position, to: position)
    }
  }

  /// Runs the full pipeline for a candidate text:
  /// formatting → state update → validation → UI updates → callbacks.
  func processIncomingText(_ candidateText: String) {
    // 1) Normalize and format.
    let result = formatter.format(text: candidateText, rule: configuration.inputRule)
    textState.rawText = result.rawText
    textState.formattedText = result.formattedText
    text = result.formattedText
    let previousIsValid = validationResult.isValid
    // 2) Validate if configured on change.
    if configuration.validationPolicy.trigger == .onChange {
      performValidation(for: result, source: .onChange)
    } else {
      textState.errorMessage = nil
    }
    // 3) Refresh UI decorations.
    updateFloatingTitleVisibility()
    updateInlineErrorLabel()
    updateCounterLabel()
    applyStateStyle()
    // 4) Notify callbacks (optionally debounced).
    dispatchCallbacks(result: result)
    onEditingChanged?(result.rawText, result.formattedText)
    // 5) Optionally perform validation feedback animations.
    if configuration.validationFeedback.shakesOnInvalid, previousIsValid, !validationResult.isValid {
      fk_shake(
        amplitude: configuration.validationFeedback.shakeAmplitude,
        shakes: configuration.validationFeedback.shakeCount,
        duration: configuration.validationFeedback.shakeDuration
      )
    }
    // 6) Check fixed-length completion conditions.
    checkCompletion()
  }

  func applySyncValidation(for result: FKTextFieldFormattingResult) {
    if configuration.validationPolicy.ignoresEmptyInput, result.rawText.isEmpty {
      validationResult = .valid
      textState.errorMessage = nil
      return
    }
    validationResult = validator.validate(rawText: result.rawText, formattedText: result.formattedText, rule: configuration.inputRule)
    textState.errorMessage = validationResult.isValid ? nil : (validationResult.message ?? configuration.messages.error)
    if !validationResult.isValid {
      onDidFailValidation?(validationResult)
    }
    onValidationResult?(validationResult)
    runAsyncValidationIfNeeded(result: result)
  }

  func performValidation(for result: FKTextFieldFormattingResult, source: FKTextFieldValidationTrigger) {
    guard configuration.validationPolicy.trigger == source else { return }
    validationDebounceTask?.cancel()
    let debounce = configuration.validationPolicy.debounceInterval
    guard debounce > 0 else {
      applySyncValidation(for: result)
      return
    }
    let task = DispatchWorkItem(block: { [self] in
      self.applySyncValidation(for: result)
    })
    validationDebounceTask = task
    DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: task)
  }

  static func inferredTextContentType(for formatType: FKTextFieldFormatType) -> UITextContentType? {
    switch formatType {
    case .phoneNumber:
      return .telephoneNumber
    case .email:
      return .emailAddress
    case .password:
      return .password
    case .verificationCode:
      return .oneTimeCode
    case .bankCard:
      return .creditCardNumber
    case .idCard, .amount, .numeric, .alphabetic, .alphaNumeric, .custom:
      return nil
    }
  }

  static func inferredReturnKeyType(for behavior: FKTextFieldInputRule.ReturnKeyBehavior) -> UIReturnKeyType {
    switch behavior {
    case .next:
      return .next
    case .dismiss:
      return .done
    case .system:
      return .default
    }
  }

  static func inferredAutocapitalization(for formatType: FKTextFieldFormatType) -> UITextAutocapitalizationType {
    switch formatType {
    case .alphabetic:
      return .words
    case .email, .password, .phoneNumber, .numeric, .bankCard, .verificationCode, .amount, .idCard, .alphaNumeric, .custom:
      return .none
    }
  }

  func runAsyncValidationIfNeeded(result: FKTextFieldFormattingResult) {
    asyncValidationTask?.cancel()
    guard validationResult.isValid, let asyncValidator else { return }
    asyncValidationToken += 1
    let token = asyncValidationToken
    asyncValidationTask = Task { [weak self] in
      guard let self else { return }
      let asyncResult = await asyncValidator.validateAsync(rawText: result.rawText, formattedText: result.formattedText, rule: configuration.inputRule)
      guard !Task.isCancelled, token == self.asyncValidationToken else { return }
      self.validationResult = asyncResult
      if asyncResult.isValid {
        if self.configuration.validationPolicy.marksSuccessOnAsyncPass {
          self.configuration.messages.success = self.configuration.messages.success ?? ""
        }
        self.textState.errorMessage = nil
      } else {
        self.textState.errorMessage = asyncResult.message
        self.onDidFailValidation?(asyncResult)
      }
      self.onValidationResult?(asyncResult)
      self.updateInlineErrorLabel()
      self.applyStateStyle()
    }
  }

  /// Dispatches public callbacks with optional debounce.
  func dispatchCallbacks(result: FKTextFieldFormattingResult) {
    debounceTask?.cancel()
    let callback = { [weak self] in
      guard let self else { return }
      self.onFormattedResult?(result)
    }
    let delay = configuration.inputRule.debounceInterval
    if delay > 0 {
      // Debounce on main queue to keep UI updates consistent.
      let task = DispatchWorkItem(block: callback)
      debounceTask = task
      DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    } else {
      callback()
    }
  }

  /// Fires completion callback when the current format type has a fixed length and is reached.
  func checkCompletion() {
    guard let fixedLength = configuration.inputRule.formatType.fixedLength else { return }
    guard textState.rawText.count == fixedLength else { return }
    onInputCompleted?(textState.rawText)
    if configuration.inputRule.autoDismissKeyboardOnComplete {
      resignFirstResponder()
    }
  }

  /// Re-applies formatting/validation to the current text value.
  func reformatCurrentText() {
    processIncomingText(text ?? "")
  }

  /// Handles `.editingChanged` events and keeps the pipeline in sync.
  @objc func editingChanged() {
    processIncomingText(text ?? "")
  }

  /// Handles `.editingDidBegin` events to refresh focus style.
  @objc func editingDidBegin() {
    onDidBeginEditing?()
    applyStateStyle()
  }

  /// Handles `.editingDidEnd` events to finalize validation and update UI state.
  @objc func editingDidEnd() {
    onDidEndEditing?()
    performValidation(
      for: .init(
        rawText: textState.rawText,
        formattedText: textState.formattedText,
        isTruncated: false,
        removedIllegalCharacters: false
      ),
      source: .onBlur
    )
    updateInlineErrorLabel()
    updateFloatingTitleVisibility()
    applyStateStyle()
    forwardingDelegate?.textFieldDidEndEditing?(self)
  }

  /// Toggles password visibility and notifies the toggle callback.
  @objc func togglePasswordVisible() {
    isPasswordVisible.toggle()
    onPasswordVisibilityToggled?(isPasswordVisible)
  }

  /// Clears current content when the built-in clear button is tapped.
  @objc func didTapClearButton() {
    clear()
    onDidClear?()
    if configuration.accessories.clearButton.resignsFirstResponderOnTap {
      resignFirstResponder()
    }
  }

  /// Updates the built-in counter label text when enabled.
  func updateCounterLabel() {
    guard configuration.counter.isEnabled else { return }
    let maxCount = configuration.counter.maxCount ?? configuration.inputRule.maxLength
    if let maxCount {
      counterLabel.text = "\(textState.rawText.count)/\(max(0, maxCount))"
    } else {
      counterLabel.text = "\(textState.rawText.count)"
    }
    if configuration.accessibility.announcesCounterChanges, UIAccessibility.isVoiceOverRunning, let counterText = counterLabel.text {
      UIAccessibility.post(
        notification: .announcement,
        argument: "\(configuration.localization.counterAnnouncementPrefix): \(counterText)"
      )
    }
  }

  /// Updates the inline error label visibility and content based on current state.
  func updateInlineErrorLabel() {
    guard configuration.inlineMessage.showsErrorMessage else {
      inlineErrorLabel.isHidden = true
      return
    }
    let resolvedStatus = resolvedStatus()
    switch resolvedStatus {
    case .error:
      inlineErrorLabel.font = configuration.inlineMessage.errorFont
      inlineErrorLabel.textColor = configuration.inlineMessage.errorColor
      inlineErrorLabel.text = textState.errorMessage ?? configuration.messages.error
      inlineErrorLabel.isHidden = inlineErrorLabel.text?.isEmpty ?? true
      announceForAccessibilityIfNeeded(prefix: configuration.localization.errorAnnouncementPrefix, message: inlineErrorLabel.text)
    case .success:
      inlineErrorLabel.font = configuration.inlineMessage.helperFont
      inlineErrorLabel.textColor = configuration.inlineMessage.successColor
      inlineErrorLabel.text = configuration.messages.success
      inlineErrorLabel.isHidden = inlineErrorLabel.text?.isEmpty ?? true
      announceForAccessibilityIfNeeded(prefix: configuration.localization.successAnnouncementPrefix, message: inlineErrorLabel.text)
    default:
      inlineErrorLabel.font = configuration.inlineMessage.helperFont
      inlineErrorLabel.textColor = configuration.inlineMessage.helperColor
      inlineErrorLabel.text = configuration.messages.helper
      inlineErrorLabel.isHidden = inlineErrorLabel.text?.isEmpty ?? true
    }
  }

  func updateFloatingTitleVisibility() {
    let shouldShow = !(configuration.floatingTitle ?? "").isEmpty && (isFirstResponder || !(textState.rawText.isEmpty))
    floatingTitleLabel.isHidden = !shouldShow
  }

  func updateAccessibilityConfiguration() {
    accessibilityTraits = configuration.isReadOnly ? [.staticText] : [.updatesFrequently]
    if configuration.isReadOnly {
      accessibilityHint = configuration.messages.helper
    }
  }

  func announceForAccessibilityIfNeeded(prefix: String, message: String?) {
    guard configuration.accessibility.announcesStatusChanges else { return }
    guard UIAccessibility.isVoiceOverRunning, let message, !message.isEmpty else { return }
    UIAccessibility.post(notification: .announcement, argument: "\(prefix): \(message)")
  }
}

extension FKTextField {
  /// Returns an intrinsic height that optionally includes inline message content.
  public override var intrinsicContentSize: CGSize {
    let base = configuration.layout.textAreaHeight
    let floatingHeight: CGFloat = floatingTitleLabel.isHidden ? 0 : (configuration.style.floatingTitleFont.lineHeight + 4)
    let messageHeight: CGFloat
    if configuration.inlineMessage.showsErrorMessage, !inlineErrorLabel.isHidden {
      messageHeight = configuration.layout.inlineMessageSpacing + inlineErrorLabel.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude)).height
    } else {
      messageHeight = 0
    }
    return CGSize(width: UIView.noIntrinsicMetric, height: base + floatingHeight + messageHeight)
  }

  /// Lays out the inline error label under the text area when enabled.
  public override func layoutSubviews() {
    super.layoutSubviews()

    // Underline frame depends on bounds and is orthogonal to inline messaging.
    if case let .underline(thickness, insets) = configuration.decoration.mode {
      let height = max(1, thickness)
      let y = bounds.height - height - max(0, insets.bottom)
      let x = max(0, insets.left)
      let width = max(0, bounds.width - x - max(0, insets.right))
      underlineLayer.frame = CGRect(x: x, y: y, width: width, height: height)
    }

    let floatingHeight: CGFloat = floatingTitleLabel.isHidden ? 0 : (configuration.style.floatingTitleFont.lineHeight + 4)
    if !floatingTitleLabel.isHidden {
      floatingTitleLabel.frame = CGRect(
        x: configuration.layout.contentInsets.left,
        y: 0,
        width: bounds.width - configuration.layout.contentInsets.left - configuration.layout.contentInsets.right,
        height: floatingHeight
      )
    }
    guard configuration.inlineMessage.showsErrorMessage, !inlineErrorLabel.isHidden else { return }
    let baseHeight = configuration.layout.textAreaHeight
    let y = floatingHeight + baseHeight + configuration.layout.inlineMessageSpacing
    let messageHeight = max(0, bounds.height - y)
    inlineErrorLabel.frame = CGRect(
      x: configuration.layout.contentInsets.left,
      y: y,
      width: bounds.width - configuration.layout.contentInsets.left - configuration.layout.contentInsets.right,
      height: messageHeight
    )
  }

  /// Applies custom insets to the non-editing text rect.
  public override func textRect(forBounds bounds: CGRect) -> CGRect {
    rectForTextArea(super.textRect(forBounds: bounds))
  }

  /// Applies custom insets to the editing text rect.
  public override func editingRect(forBounds bounds: CGRect) -> CGRect {
    rectForTextArea(super.editingRect(forBounds: bounds))
  }

  /// Applies custom insets to the placeholder rect.
  public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    rectForTextArea(super.placeholderRect(forBounds: bounds))
  }

  /// Returns the base text area rect (without inline message).
  func rectForTextArea(_ baseRect: CGRect) -> CGRect {
    var insets = configuration.layout.contentInsets
    insets.top = max(0, insets.top)
    insets.left = max(0, insets.left)
    insets.bottom = max(0, insets.bottom)
    insets.right = max(0, insets.right)
    if !floatingTitleLabel.isHidden {
      insets.top += configuration.style.floatingTitleFont.lineHeight + 4
    }
    return baseRect.inset(by: insets)
  }
}

extension FKTextField: FKTextInputComponent {
  public var fk_rawText: String { rawText }
  public func fk_setText(_ text: String) {
    processIncomingText(text)
  }
  public func fk_clear() {
    clear()
  }
}

extension FKTextField: UITextFieldDelegate {
  /// Intercepts character changes to apply formatting and validation deterministically.
  ///
  /// - Note: This returns `false` because `FKTextField` assigns the formatted output itself.
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if configuration.isReadOnly {
      return false
    }
    // Respect marked text composition (e.g. Chinese/Japanese IME) to avoid blocking input.
    if textField.markedTextRange != nil {
      return true
    }
    let currentTime = CFAbsoluteTimeGetCurrent()
    let minimumInterval = configuration.inputRule.minimumInputInterval
    if minimumInterval > 0, currentTime - lastInputTime < minimumInterval {
      return false
    }
    lastInputTime = currentTime

    guard let text = textField.text, let textRange = Range(range, in: text) else {
      return forwardingDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    // Build candidate text and run the full pipeline.
    let candidate = text.replacingCharacters(in: textRange, with: string)
    let targetCaretIndex = range.location + string.count
    let candidatePrefix = String(candidate.prefix(max(0, min(candidate.count, targetCaretIndex))))
    let rawCaretOffset = formatter.format(text: candidatePrefix, rule: configuration.inputRule).rawText.count
    processIncomingText(candidate)
    restoreCursor(rawOffset: rawCaretOffset)
    return false
  }

  /// Handles return key and optionally dismisses keyboard.
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    onDidSubmit?(textState.rawText)
    performValidation(
      for: .init(
        rawText: textState.rawText,
        formattedText: textState.formattedText,
        isTruncated: false,
        removedIllegalCharacters: false
      ),
      source: .onSubmit
    )
    switch configuration.inputRule.returnKeyBehavior {
    case .system:
      if configuration.inputRule.autoDismissKeyboardOnComplete {
        textField.resignFirstResponder()
      }
      return forwardingDelegate?.textFieldShouldReturn?(textField) ?? true
    case .dismiss:
      textField.resignFirstResponder()
      return true
    case .next:
      if let nextTextField {
        nextTextField.becomeFirstResponder()
      } else {
        textField.resignFirstResponder()
      }
      return true
    }
  }

  /// Forwards `textFieldShouldBeginEditing` if provided.
  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    if configuration.isReadOnly {
      return false
    }
    return forwardingDelegate?.textFieldShouldBeginEditing?(textField) ?? true
  }

  /// Forwards `textFieldDidBeginEditing` if provided.
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    forwardingDelegate?.textFieldDidBeginEditing?(textField)
  }
}

extension FKTextField {
  public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(paste(_:)) {
      switch configuration.inputRule.pastePolicy {
      case .allow, .allowIfValid:
        return true
      case .forbid:
        return false
      }
    }
    return super.canPerformAction(action, withSender: sender)
  }

  public override func paste(_ sender: Any?) {
    guard !configuration.isReadOnly else { return }
    guard configuration.inputRule.pastePolicy != .forbid else { return }
    guard let pasted = UIPasteboard.general.string else { return }

    // Respect IME composition.
    if markedTextRange != nil {
      super.paste(sender)
      return
    }

    let current = text ?? ""
    let selectionRange: NSRange
    if let selectedTextRange,
       let start = position(from: beginningOfDocument, offset: offset(from: beginningOfDocument, to: selectedTextRange.start)),
       let end = position(from: beginningOfDocument, offset: offset(from: beginningOfDocument, to: selectedTextRange.end)),
       let range = textRange(from: start, to: end) {
      let location = offset(from: beginningOfDocument, to: range.start)
      let length = offset(from: range.start, to: range.end)
      selectionRange = NSRange(location: location, length: length)
    } else {
      selectionRange = NSRange(location: current.count, length: 0)
    }

    guard let r = Range(selectionRange, in: current) else { return }
    let candidate = current.replacingCharacters(in: r, with: pasted)

    if configuration.inputRule.pastePolicy == .allowIfValid {
      let preview = formatter.format(text: candidate, rule: configuration.inputRule)
      let previewValidation = validator.validate(rawText: preview.rawText, formattedText: preview.formattedText, rule: configuration.inputRule)
      if !previewValidation.isValid, !preview.rawText.isEmpty {
        fk_shake(
          amplitude: configuration.validationFeedback.shakeAmplitude,
          shakes: max(2, configuration.validationFeedback.shakeCount),
          duration: max(0.2, configuration.validationFeedback.shakeDuration)
        )
        return
      }
    }

    processIncomingText(candidate)
  }
}

/// Internal state container for `FKTextField`.
private struct FKTextFieldState {
  /// Canonical raw value (no separators) used for validation and submission.
  var rawText: String = ""
  /// UI display value with separators/grouping applied.
  var formattedText: String = ""
  /// Current error message to present, if any.
  var errorMessage: String?
}

