//
// FKTextField.swift
//
// Highly customizable formatted text field.
//

import UIKit

/// A native, protocol-driven, zero-dependency formatted text field for UIKit.
///
/// `FKTextField` is a drop-in replacement for `UITextField` that provides a unified solution for:
/// - input filtering (emoji/whitespace/special character control),
/// - automatic formatting (raw vs formatted display),
/// - realtime validation and error feedback,
/// - global style defaults with per-instance overrides,
/// - reusable-list friendly behavior (no extra dependencies, deterministic formatting).
///
/// The component is designed to be configured in one line through `FKTextFieldInputRule` and
/// `FKTextFieldConfiguration`, while remaining extensible via `FKTextFieldFormatting` and
/// `FKTextFieldValidating` protocols.
@MainActor
public final class FKTextField: UITextField, FKTextFieldConfigurable {
  /// Current full configuration.
  public private(set) var configuration: FKTextFieldConfiguration

  /// Current validation result.
  public private(set) var validationResult: FKTextFieldValidationResult = .valid

  /// Closure called when raw and formatted text changes.
  public var onTextDidChange: ((String, String) -> Void)?
  /// Closure called when formatter output is produced.
  public var onFormattedResult: ((FKTextFieldFormattingResult) -> Void)?
  /// Closure called when validation result changes.
  public var onValidationResult: ((FKTextFieldValidationResult) -> Void)?
  /// Closure called when error message changes.
  public var onErrorMessage: ((String?) -> Void)?
  /// Closure called when fixed-length input is completed.
  public var onInputCompleted: ((String) -> Void)?
  /// Closure called when password visibility is toggled.
  ///
  /// The value indicates whether the password is currently visible.
  public var onPasswordVisibilityToggled: ((Bool) -> Void)?

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

  /// Formatter implementation used to produce raw/formatted output.
  private let formatter: FKTextFieldFormatting
  /// Validator implementation used to produce validity and optional messages.
  private let validator: FKTextFieldValidating
  /// Debounce work item for callback coalescing.
  private var debounceTask: DispatchWorkItem?
  /// Last accepted input timestamp for anti-burst protection.
  private var lastInputTime: CFAbsoluteTime = 0
  /// Internal state snapshot (raw/formatted/error) for current value.
  private var textState = FKTextFieldState()
  /// Built-in password visibility toggle.
  private lazy var passwordToggleButton = UIButton(type: .system)
  /// Built-in counter label used as `rightView` when enabled.
  private lazy var counterLabel = UILabel()
  /// Inline error label rendered below the text area when enabled.
  private lazy var inlineErrorLabel = UILabel()

  /// Creates a text field with custom formatter and validator.
  public init(
    configuration: FKTextFieldConfiguration,
    formatter: FKTextFieldFormatting = FKTextFieldDefaultFormatter(),
    validator: FKTextFieldValidating = FKTextFieldDefaultValidator()
  ) {
    self.configuration = configuration
    self.formatter = formatter
    self.validator = validator
    super.init(frame: .zero)
    commonInit()
  }

  /// Creates a text field using global style defaults.
  public convenience init(inputRule: FKTextFieldInputRule) {
    let configuration = FKTextFieldConfiguration(
      inputRule: inputRule,
      style: FKTextFieldManager.shared.defaultStyle
    )
    self.init(configuration: configuration)
  }

  /// Interface Builder initializer.
  public required init?(coder: NSCoder) {
    configuration = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(formatType: .alphaNumeric),
      style: FKTextFieldManager.shared.defaultStyle
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
    applyStateStyle()
    onErrorMessage?(message)
  }

  /// Clears current text and state.
  public func clear() {
    textState = FKTextFieldState()
    text = nil
    validationResult = .valid
    onTextDidChange?("", "")
    onValidationResult?(.valid)
    applyStateStyle()
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
    clearButtonMode = .whileEditing
    setupInlineViewsIfNeeded()
    applyConfiguration()
  }

  /// Applies the current configuration to UIKit properties and internal subviews.
  func applyConfiguration() {
    keyboardType = configuration.inputRule.formatType.keyboardType
    font = configuration.style.font
    textColor = configuration.style.textColor
    borderStyle = .none
    applyPlaceholder()
    configurePasswordToggleIfNeeded()
    configureCounterIfNeeded()
    applySecureTextEntry()
    applyStateStyle()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  /// Installs inline subviews used for inline messaging.
  func setupInlineViewsIfNeeded() {
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

  /// Installs or removes the built-in password toggle based on the current format type.
  func configurePasswordToggleIfNeeded() {
    guard case .password = configuration.inputRule.formatType else {
      if rightView == passwordToggleButton {
        rightView = nil
      }
      return
    }
    passwordToggleButton.setTitle("Show", for: .normal)
    passwordToggleButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
    passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisible), for: .touchUpInside)
    rightView = passwordToggleButton
    rightViewMode = .always
  }

  /// Installs or removes the built-in counter label based on the current configuration.
  func configureCounterIfNeeded() {
    guard configuration.counter.isEnabled else {
      if rightView == counterLabel {
        rightView = nil
      }
      return
    }
    guard case .password = configuration.inputRule.formatType else {
      // Preserve custom rightView when provided by the host.
      if rightView == nil || rightView == counterLabel {
        counterLabel.font = configuration.counter.font
        counterLabel.textColor = configuration.counter.color
        counterLabel.textAlignment = .right
        counterLabel.frame = CGRect(x: 0, y: 0, width: 62, height: 20)
        rightView = counterLabel
        rightViewMode = .always
      }
      return
    }
  }

  /// Applies secure text entry based on password mode and `isPasswordVisible`.
  func applySecureTextEntry() {
    guard case .password = configuration.inputRule.formatType else {
      isSecureTextEntry = false
      return
    }
    isSecureTextEntry = !isPasswordVisible
    passwordToggleButton.setTitle(isPasswordVisible ? "Hide" : "Show", for: .normal)
  }

  /// Applies the appropriate visual style for normal/focused/error state.
  func applyStateStyle() {
    let stateStyle: FKTextFieldStateStyle
    if textState.errorMessage != nil || !validationResult.isValid {
      stateStyle = configuration.style.error
    } else if isFirstResponder {
      stateStyle = configuration.style.focused
    } else {
      stateStyle = configuration.style.normal
    }

    layer.cornerRadius = stateStyle.cornerRadius
    layer.borderWidth = stateStyle.borderWidth
    layer.borderColor = stateStyle.borderColor.cgColor
    layer.backgroundColor = stateStyle.backgroundColor.cgColor
    layer.shadowColor = stateStyle.shadowColor?.cgColor
    layer.shadowOpacity = stateStyle.shadowOpacity
    layer.shadowOffset = stateStyle.shadowOffset
    layer.shadowRadius = stateStyle.shadowRadius
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
    // 2) Validate raw value (canonical representation).
    validationResult = validator.validate(rawText: result.rawText, formattedText: result.formattedText, rule: configuration.inputRule)

    // 3) Update error message state.
    if validationResult.isValid {
      textState.errorMessage = nil
    } else {
      textState.errorMessage = validationResult.message
    }

    // 4) Refresh UI decorations.
    updateInlineErrorLabel()
    updateCounterLabel()
    applyStateStyle()
    // 5) Notify callbacks (optionally debounced).
    dispatchCallbacks(result: result, validationResult: validationResult)
    onErrorMessage?(textState.errorMessage)
    // 6) Optionally perform validation feedback animations.
    if configuration.validationFeedback.shakesOnInvalid, previousIsValid, !validationResult.isValid {
      fk_shake(
        amplitude: configuration.validationFeedback.shakeAmplitude,
        shakes: configuration.validationFeedback.shakeCount,
        duration: configuration.validationFeedback.shakeDuration
      )
    }
    // 7) Check fixed-length completion conditions.
    checkCompletion()
  }

  /// Dispatches public callbacks with optional debounce.
  func dispatchCallbacks(
    result: FKTextFieldFormattingResult,
    validationResult: FKTextFieldValidationResult
  ) {
    debounceTask?.cancel()
    let callback = { [weak self] in
      guard let self else { return }
      self.onFormattedResult?(result)
      self.onTextDidChange?(result.rawText, result.formattedText)
      self.onValidationResult?(validationResult)
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
    applyStateStyle()
  }

  /// Handles `.editingDidEnd` events to finalize validation and update UI state.
  @objc func editingDidEnd() {
    validationResult = validator.validate(rawText: textState.rawText, formattedText: textState.formattedText, rule: configuration.inputRule)
    if !validationResult.isValid {
      textState.errorMessage = validationResult.message
      onErrorMessage?(textState.errorMessage)
    }
    updateInlineErrorLabel()
    applyStateStyle()
    forwardingDelegate?.textFieldDidEndEditing?(self)
  }

  /// Toggles password visibility and notifies the toggle callback.
  @objc func togglePasswordVisible() {
    isPasswordVisible.toggle()
    onPasswordVisibilityToggled?(isPasswordVisible)
  }

  /// Updates the built-in counter label text when enabled.
  func updateCounterLabel() {
    guard configuration.counter.isEnabled else { return }
    guard rightView == counterLabel else { return }
    let maxCount = configuration.counter.maxCount ?? configuration.inputRule.maxLength
    if let maxCount {
      counterLabel.text = "\(textState.rawText.count)/\(max(0, maxCount))"
    } else {
      counterLabel.text = "\(textState.rawText.count)"
    }
  }

  /// Updates the inline error label visibility and content based on current state.
  func updateInlineErrorLabel() {
    guard configuration.inlineMessage.showsErrorMessage else {
      inlineErrorLabel.isHidden = true
      return
    }
    inlineErrorLabel.font = configuration.inlineMessage.errorFont
    inlineErrorLabel.textColor = configuration.inlineMessage.errorColor
    inlineErrorLabel.text = textState.errorMessage
    inlineErrorLabel.isHidden = (textState.errorMessage == nil)
  }
}

extension FKTextField {
  /// Returns an intrinsic height that optionally includes inline message content.
  public override var intrinsicContentSize: CGSize {
    let base = configuration.layout.textAreaHeight
    guard configuration.inlineMessage.showsErrorMessage, !inlineErrorLabel.isHidden else {
      return CGSize(width: UIView.noIntrinsicMetric, height: base)
    }
    let messageHeight = inlineErrorLabel.sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude)).height
    return CGSize(width: UIView.noIntrinsicMetric, height: base + configuration.layout.inlineMessageSpacing + messageHeight)
  }

  /// Lays out the inline error label under the text area when enabled.
  public override func layoutSubviews() {
    super.layoutSubviews()
    guard configuration.inlineMessage.showsErrorMessage, !inlineErrorLabel.isHidden else { return }
    let baseHeight = configuration.layout.textAreaHeight
    let y = baseHeight + configuration.layout.inlineMessageSpacing
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
    return baseRect.inset(by: insets)
  }
}

extension FKTextField: UITextFieldDelegate {
  /// Intercepts character changes to apply formatting and validation deterministically.
  ///
  /// - Note: This returns `false` because `FKTextField` assigns the formatted output itself.
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
    processIncomingText(candidate)
    return false
  }

  /// Handles return key and optionally dismisses keyboard.
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if configuration.inputRule.autoDismissKeyboardOnComplete {
      textField.resignFirstResponder()
    }
    return forwardingDelegate?.textFieldShouldReturn?(textField) ?? true
  }

  /// Forwards `textFieldShouldBeginEditing` if provided.
  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    forwardingDelegate?.textFieldShouldBeginEditing?(textField) ?? true
  }

  /// Forwards `textFieldDidBeginEditing` if provided.
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    forwardingDelegate?.textFieldDidBeginEditing?(textField)
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

