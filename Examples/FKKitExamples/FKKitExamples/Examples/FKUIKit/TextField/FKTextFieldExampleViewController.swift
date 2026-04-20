//
// FKTextFieldExampleViewController.swift
//
// Complete copy-ready demo for FKTextField composite scenarios.
//

import UIKit
import FKUIKit

// MARK: - Global configuration

/// Shared setup helpers for FKTextField demo screens.
enum FKTextFieldDemoSupport {
  private static var didConfigureGlobalStyle = false

  /// Configures a global text field style once.
  static func configureGlobalStyleIfNeeded() {
    guard !didConfigureGlobalStyle else { return }
    didConfigureGlobalStyle = true
    FKTextFieldManager.shared.configureDefaultStyle { style in
      style.normal.cornerRadius = 10
      style.normal.borderColor = .systemGray4
      style.normal.backgroundColor = .secondarySystemBackground
      style.focused.borderColor = .systemBlue
      style.error.borderColor = .systemRed
      style.placeholderColor = .tertiaryLabel
    }
  }
}

// MARK: - View controller

/// A single screen that covers formatting, validation, callbacks, and UI customization.
///
/// This file is intentionally self-contained so it can be copied into other projects.
final class FKTextFieldExampleViewController: UIViewController {

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let callbackLogLabel = UILabel()

  // Cached references for demo interactions.
  private var clearables: [() -> Void] = []
  private weak var firstAutoFocusTarget: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    FKTextFieldDemoSupport.configureGlobalStyleIfNeeded()
    title = "FKTextField"
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    buildExamples()
    configureNavigationActions()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Demonstrate auto focus for verification code input.
    if let target = firstAutoFocusTarget as? UIKeyInput {
      _ = (target as? UIView)?.becomeFirstResponder()
    } else {
      firstAutoFocusTarget?.becomeFirstResponder()
    }
  }
}

private extension FKTextFieldExampleViewController {
  func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    view.addSubview(scrollView)

    contentStack.axis = .vertical
    contentStack.spacing = 18
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    callbackLogLabel.font = .preferredFont(forTextStyle: .footnote)
    callbackLogLabel.textColor = .secondaryLabel
    callbackLogLabel.numberOfLines = 0
    callbackLogLabel.text = "Callback log will be shown here."
    contentStack.addArrangedSubview(makeSectionTitle("Live Callback Log"))
    contentStack.addArrangedSubview(callbackLogLabel)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  func buildExamples() {
    addFeatureSectionFormattedInputs()
    addFeatureSectionVerificationCodes()
    addFeatureSectionPassword()
    addFeatureSectionTextViewCounter()
    addFeatureSectionCustomUIAndCallbacks()
  }

  // MARK: - Feature sections

  func addFeatureSectionFormattedInputs() {
    let section = makeSectionContainer(
      title: "Formatted Inputs",
      subtitle: "Phone / ID card / bank card formatting + validation and filtering (no emoji/special/space)."
    )

    let phone = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone (3-4-4)")
      .chain { $0.clearButtonMode = .whileEditing }
    bind(field: phone, name: "Phone")
    registerClearable { [weak phone] in phone?.clear() }

    let id = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .idCard,
        maxLength: 18,
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    id.placeholder = "ID card (15/18, checksum validated)"
    bind(field: id, name: "IDCard")
    registerClearable { [weak id] in id?.clear() }

    let bank = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .bankCard,
        maxLength: 24,
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    bank.placeholder = "Bank card (grouped by 4)"
    bind(field: bank, name: "BankCard")
    registerClearable { [weak bank] in bank?.clear() }

    let validateButton = makeActionButton(title: "Validate & Shake Invalid") { [weak self, weak phone, weak id, weak bank] in
      guard let self else { return }
      // Demonstrate explicit validation feedback (e.g. after submit).
      let candidates: [(String, FKTextField?)] = [("Phone", phone), ("IDCard", id), ("BankCard", bank)]
      for (name, f) in candidates {
        guard let f else { continue }
        if f.validationResult.isValid == false {
          f.shakeForValidationFailure()
          self.appendLog("\(name) invalid -> shake triggered")
        }
      }
    }

    section.addArrangedSubview(makeLabeledField("Phone number", field: phone))
    section.addArrangedSubview(makeLabeledField("ID card", field: id))
    section.addArrangedSubview(makeLabeledField("Bank card", field: bank))
    section.addArrangedSubview(validateButton)
    contentStack.addArrangedSubview(section)
  }

  func addFeatureSectionVerificationCodes() {
    let section = makeSectionContainer(
      title: "Verification Codes",
      subtitle: "4/6-digit numeric input with auto focus, AutoFill and completion callback."
    )

    // 6-digit formatted input (classic).
    let formattedOTP = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .verificationCode(length: 6, allowsAlphabet: false),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false,
        autoDismissKeyboardOnComplete: true
      )
    )
    formattedOTP.placeholder = "OTP (formatted type, 6 digits)"
    formattedOTP.onInputCompleted = { [weak self] code in
      self?.appendLog("OTP finished (FKTextField): \(code)")
    }
    bind(field: formattedOTP, name: "OTP-Formatted")
    registerClearable { [weak formattedOTP] in formattedOTP?.clear() }

    // 4-digit slot input with underlines.
    var cfg4 = FKCodeTextField.Configuration(length: 4, slotStyle: .underlines)
    cfg4.slotSpacing = 12
    cfg4.underlineHeight = 2
    let slot4 = FKCodeTextField(configuration: cfg4)
    slot4.translatesAutoresizingMaskIntoConstraints = false
    slot4.heightAnchor.constraint(equalToConstant: 52).isActive = true
    slot4.onCodeCompleted = { [weak self] code in
      self?.appendLog("OTP finished (slot 4): \(code)")
    }
    registerClearable { [weak slot4] in slot4?.clearCode() }

    // 6-digit slot input with boxes.
    var cfg6 = FKCodeTextField.Configuration(length: 6, slotStyle: .boxes)
    cfg6.slotSpacing = 10
    cfg6.cornerRadius = 10
    let slot6 = FKCodeTextField(configuration: cfg6)
    slot6.translatesAutoresizingMaskIntoConstraints = false
    slot6.heightAnchor.constraint(equalToConstant: 52).isActive = true
    slot6.onCodeCompleted = { [weak self, weak slot6] code in
      self?.appendLog("OTP finished (slot 6): \(code)")
      // Demonstrate error feedback for wrong code.
      if code != "123456" {
        slot6?.setErrorState(true, shakes: true)
      }
    }
    registerClearable { [weak slot6] in slot6?.clearCode() }

    // Auto focus the first code control on appear.
    if firstAutoFocusTarget == nil {
      firstAutoFocusTarget = slot4
    }

    section.addArrangedSubview(makeLabeledField("OTP (FKTextField)", field: formattedOTP))
    section.addArrangedSubview(makeLabeledCustom("OTP 4 (slot underlines)", view: slot4))
    section.addArrangedSubview(makeLabeledCustom("OTP 6 (slot boxes, AutoFill)", view: slot6))
    contentStack.addArrangedSubview(section)
  }

  func addFeatureSectionPassword() {
    let section = makeSectionContainer(
      title: "Password Input",
      subtitle: "Built-in show/hide toggle, strength validation, toggle callback and clear support."
    )

    let password = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    password.placeholder = "Password (8+ with strength rule)"
    password.onPasswordVisibilityToggled = { [weak self] isVisible in
      self?.appendLog("Password toggle tapped -> visible: \(isVisible)")
    }
    bind(field: password, name: "Password")
    registerClearable { [weak password] in password?.clear() }

    section.addArrangedSubview(makeLabeledField("Password", field: password))
    contentStack.addArrangedSubview(section)
  }

  func addFeatureSectionTextViewCounter() {
    let section = makeSectionContainer(
      title: "Text View with Counter",
      subtitle: "A UITextView subclass with placeholder, realtime counter and max length interception."
    )

    let tv = FKCountTextView(
      configuration: FKCountTextView.Configuration(
        maxLength: 120,
        showsCounter: true,
        placeholder: "Multi-line input (max 120)"
      )
    )
    tv.font = .systemFont(ofSize: 15)
    tv.onTextChanged = { [weak self] text in
      self?.appendLog("TextView didChange -> \(text.count) chars")
    }
    tv.onOverflowAttempt = { [weak self] _ in
      self?.appendLog("TextView overflow -> rejected + shake")
    }
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.heightAnchor.constraint(equalToConstant: 140).isActive = true
    registerClearable { [weak tv] in tv?.text = "" }

    section.addArrangedSubview(makeLabeledCustom("Count text view", view: tv))
    contentStack.addArrangedSubview(section)
  }

  func addFeatureSectionCustomUIAndCallbacks() {
    let section = makeSectionContainer(
      title: "Custom UI + Callbacks + Auto Dismiss",
      subtitle: "Custom border/corner/placeholder/icons, counter + inline error, emoji filtering, and auto dismiss keyboard on completion."
    )

    // Custom regex + grouping.
    let customRegex = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(
          regex: "[A-Za-z0-9]",
          maxLength: 12,
          separator: "-",
          groupPattern: [4, 4, 4]
        ),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    customRegex.placeholder = "Serial (XXXX-XXXX-XXXX)"
    bind(field: customRegex, name: "CustomRegex")
    registerClearable { [weak customRegex] in customRegex?.clear() }

    // Counter + inline error + auto shake when invalid.
    let configuration = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(
        formatType: .email,
        maxLength: 64,
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: true,
        autoDismissKeyboardOnComplete: true
      ),
      inlineMessage: FKTextFieldInlineMessageConfiguration(showsErrorMessage: true),
      counter: FKTextFieldCounterConfiguration(isEnabled: true),
      validationFeedback: FKTextFieldValidationFeedbackConfiguration(shakesOnInvalid: true),
      placeholder: "Email (counter + inline error + auto shake)"
    )
    let email = FKTextField(configuration: configuration)
    bind(field: email, name: "Email+Inline")
    registerClearable { [weak email] in email?.clear() }

    // Custom left icon + clear + custom right icon.
    let actionField = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone with left/right icons")
    actionField.clearButtonMode = .whileEditing
    bind(field: actionField, name: "ActionField")
    registerClearable { [weak actionField] in actionField?.clear() }

    let leftIcon = UIImageView(image: UIImage(systemName: "phone.fill"))
    leftIcon.tintColor = .secondaryLabel
    leftIcon.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
    actionField.leftView = leftIcon
    actionField.leftViewMode = .always

    let sendButton = UIButton(type: .system)
    sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    sendButton.tintColor = .systemBlue
    sendButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
    sendButton.addAction(UIAction { [weak self, weak actionField] _ in
      guard let self, let actionField else { return }
      self.appendLog("Right icon tapped -> raw: \(actionField.rawText)")
    }, for: .touchUpInside)
    actionField.rightView = sendButton
    actionField.rightViewMode = .always

    section.addArrangedSubview(makeLabeledField("Custom regex", field: customRegex))
    section.addArrangedSubview(makeLabeledField("Email (inline error + counter)", field: email))
    section.addArrangedSubview(makeLabeledField("Icons + clear + right action", field: actionField))
    contentStack.addArrangedSubview(section)
  }

  // MARK: - Navigation actions

  func configureNavigationActions() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Clear",
        image: nil,
        primaryAction: UIAction { [weak self] _ in
          self?.clearAll()
        },
        menu: nil
      ),
      UIBarButtonItem(
        title: "Dismiss",
        image: nil,
        primaryAction: UIAction { [weak self] _ in
          self?.view.endEditing(true)
          self?.appendLog("Keyboard dismissed")
        },
        menu: nil
      ),
    ]
  }

  func clearAll() {
    clearables.forEach { $0() }
    appendLog("All inputs cleared")
  }

  func registerClearable(_ block: @escaping () -> Void) {
    clearables.append(block)
  }

  // MARK: - Callbacks

  func bind(field: FKTextField, name: String) {
    field.onTextDidChange = { [weak self] raw, formatted in
      self?.appendLog("\(name) didChange -> raw: \(raw), formatted: \(formatted)")
    }
    field.onInputCompleted = { [weak self] raw in
      self?.appendLog("\(name) didFinish -> \(raw)")
    }
    field.onValidationResult = { [weak self] result in
      self?.appendLog("\(name) validation -> \(result.isValid ? "valid" : "invalid")")
    }
    field.onErrorMessage = { [weak self] message in
      if let message {
        self?.appendLog("\(name) error -> \(message)")
      }
    }
  }

  func appendLog(_ text: String) {
    callbackLogLabel.text = text
  }

  // MARK: - UI helpers

  func makeSectionContainer(title: String, subtitle: String) -> UIStackView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10
    container.addArrangedSubview(makeSectionTitle(title))
    container.addArrangedSubview(makeSectionSubtitle(subtitle))
    return container
  }

  func makeLabeledField(_ title: String, field: FKTextField) -> UIStackView {
    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    row.addArrangedSubview(makeMinorLabel(title))
    row.addArrangedSubview(field)
    return row
  }

  func makeLabeledCustom(_ title: String, view: UIView) -> UIStackView {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    row.addArrangedSubview(makeMinorLabel(title))
    row.addArrangedSubview(view)
    return row
  }

  func makeMinorLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.text = text
    return label
  }

  func makeActionButton(title: String, action: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.backgroundColor = .secondarySystemFill
    b.layer.cornerRadius = 8
    b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    b.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return b
  }

  func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.text = text
    return label
  }

  func makeSectionSubtitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}

// MARK: - Chain helper

private extension FKTextField {
  /// Lightweight chain helper used for demo readability.
  @discardableResult
  func chain(_ block: (FKTextField) -> Void) -> FKTextField {
    block(self)
    return self
  }
}

