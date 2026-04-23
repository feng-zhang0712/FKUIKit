import UIKit
import SwiftUI
import FKUIKit

// MARK: - Main Hub

final class FKTextFieldExampleViewController: UITableViewController {
  private struct Item {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let items: [Item] = [
    Item(title: "Basics", subtitle: "Placeholder, default value, clear button, disabled and read-only", make: { FKTextFieldBasicStyleExampleViewController() }),
    Item(title: "Types & Formatting", subtitle: "Email, phone, password, decimal, OTP, bank card and raw/display mapping", make: { FKTextFieldFormatFilterExampleViewController() }),
    Item(title: "Status Gallery", subtitle: "Validate normal/focused/error/success/disabled/read-only visual states", make: { FKTextFieldStateGalleryExampleViewController() }),
    Item(title: "Validation Strategies", subtitle: "Compare onChange/onBlur/onSubmit with sync + async validation", make: { FKTextFieldValidationExampleViewController() }),
    Item(title: "Form Orchestration", subtitle: "Focus chaining, return key submit and first-error refocus", make: { FKTextFieldFormExampleViewController() }),
    Item(title: "OTP & Counter Input", subtitle: "OTP(FKTextField), OTP4/OTP6 slots, TextView with counter", make: { FKTextFieldOtpCounterExampleViewController() }),
    Item(title: "I18N & Accessibility", subtitle: "English/Chinese switch, RTL, Dynamic Type, VoiceOver notes", make: { FKTextFieldI18NExampleViewController() }),
    Item(title: "Theme Tokens", subtitle: "Light/Dark and token override with success/error contrast", make: { FKTextFieldThemeExampleViewController() }),
    Item(title: "XIB / Storyboard", subtitle: "Shows Interface Builder creation entry", make: { FKTextFieldIBExampleViewController() }),
    Item(title: "SwiftUI", subtitle: "UIViewRepresentable wrapper for FKTextField", make: { FKTextFieldSwiftUIExampleHostController() }),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TextField"
    view.backgroundColor = .systemGroupedBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(items[indexPath.row].make(), animated: true)
  }
}

// MARK: - Shared page UI

class FKTextFieldExamplePageViewController: UIViewController {
  let scrollView = UIScrollView()
  let stack = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    setupDismissKeyboardOnTap()
  }

  private func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = 14
    view.addSubview(scrollView)
    scrollView.addSubview(stack)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
    ])
  }

  func addSection(title: String, note: String) {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    let noteLabel = UILabel()
    noteLabel.text = note
    noteLabel.textColor = .secondaryLabel
    noteLabel.font = .preferredFont(forTextStyle: .footnote)
    noteLabel.numberOfLines = 0
    stack.addArrangedSubview(noteLabel)
  }

  func addField(title: String, field: FKTextField, ruleHint: String? = nil) {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    row.addArrangedSubview(field)
    if let ruleHint, !ruleHint.isEmpty {
      let hintLabel = UILabel()
      hintLabel.text = ruleHint
      hintLabel.textColor = .tertiaryLabel
      hintLabel.font = .preferredFont(forTextStyle: .caption2)
      hintLabel.numberOfLines = 0
      row.addArrangedSubview(hintLabel)
    }
    stack.addArrangedSubview(row)
  }

  func addCustomView(title: String, view customView: UIView) {
    let row = UIStackView()
    row.axis = .vertical
    row.spacing = 6
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    row.addArrangedSubview(customView)
    stack.addArrangedSubview(row)
  }

  private func setupDismissKeyboardOnTap() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(endEdit))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }

  @objc private func endEdit() {
    view.endEditing(true)
  }
}

// MARK: - Basics & style

final class FKTextFieldBasicStyleExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics"
    build()
  }

  private func build() {
    addSection(title: "Basic Text Input", note: "Verifies placeholder rendering, default value hydration, clear action, and reusable UIKit setup.")
    let basic = FKTextField.make(formatType: .alphaNumeric, placeholder: "Enter username")
    basic.fk_setText("DefaultValue123")
    addField(title: "Placeholder + default value", field: basic, ruleHint: "Allowed: A-Z, a-z, 0-9. Blocked: spaces, emoji, symbols.")

    addSection(title: "Clear Button Behavior", note: "Verifies built-in clear button callback and state reset path used by production forms.")
    var clearConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    clearConfig.accessories.clearButton.isEnabled = true
    clearConfig.placeholder = "Type and tap clear"
    let clearField = FKTextField(configuration: clearConfig)
    let clearResult = UILabel()
    clearResult.textColor = .secondaryLabel
    clearResult.font = .preferredFont(forTextStyle: .footnote)
    clearResult.text = "Clear callback: waiting"
    clearField.onDidClear = { [weak clearResult] in
      clearResult?.text = "Clear callback: fired"
    }
    addField(title: "Custom clear button", field: clearField, ruleHint: "Allowed: A-Z, a-z, 0-9. Blocked: spaces, emoji, symbols.")
    stack.addArrangedSubview(clearResult)

    addSection(title: "Disabled / Read-only", note: "Verifies immutable states: disabled blocks interactions entirely; read-only keeps value visible while editing is blocked.")
    let disabled = FKTextField.make(formatType: .alphaNumeric, placeholder: "Disabled field")
    disabled.isEnabled = false
    disabled.fk_setText("DisabledValue")
    addField(title: "Disabled state", field: disabled, ruleHint: "Rule allows A-Z, a-z, 0-9, but editing is disabled.")

    var readOnlyConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    readOnlyConfig.isReadOnly = true
    readOnlyConfig.placeholder = "Read-only field"
    readOnlyConfig.messages.helper = "This value can be copied but not edited."
    readOnlyConfig.inlineMessage.showsErrorMessage = true
    readOnlyConfig.layout.inlineMessageSpacing = 8
    readOnlyConfig.layout.contentInsets = UIEdgeInsets(top: 0, left: 12, bottom: 4, right: 12)
    let readOnly = FKTextField(configuration: readOnlyConfig)
    readOnly.fk_setText("ReadonlyValue")
    addField(title: "Read-only state", field: readOnly, ruleHint: "Rule allows A-Z, a-z, 0-9, but field is read-only.")

    addSection(title: "Any Character Input", note: "Use this setup when your business requires fully unrestricted text including emoji and symbols.")
    let anyInput = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[\\s\\S]", maxLength: nil, separator: nil, groupPattern: []),
        allowedInput: .any,
        allowsWhitespace: true,
        allowsEmoji: true,
        allowsSpecialCharacters: true
      )
    )
    anyInput.placeholder = "Try: 中文 abc 123 !@# 😄"
    addField(title: "Unrestricted input", field: anyInput, ruleHint: "Allowed: any character (letters, digits, spaces, symbols, emoji, CJK).")
  }
}

// MARK: - Formatting & filtering

final class FKTextFieldFormatFilterExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Types & Formatting"
    build()
  }

  private func build() {
    addSection(title: "Common Types", note: "Verifies ready-to-use APIs for email, phone, password, numeric/decimal and OTP input.")
    addField(title: "Email", field: FKTextField.makeEmail(placeholder: "name@example.com"), ruleHint: "Allowed: common email characters.")
    addField(title: "Phone", field: FKTextField.makePhone(placeholder: "+86 138 0000 0000"), ruleHint: "Allowed: digits only. Display uses grouping.")
    addField(title: "Password", field: FKTextField.makePassword(), ruleHint: "Allowed: password characters. Min/max and strength rules apply.")
    addField(title: "Numeric", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .numeric)), ruleHint: "Allowed: digits only.")
    addField(title: "Decimal amount", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .amount(maxIntegerDigits: 10, decimalDigits: 2))), ruleHint: "Allowed: digits and one decimal point.")
    addField(title: "OTP (6 digits)", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .verificationCode(length: 6, allowsAlphabet: false))), ruleHint: "Allowed: digits only, fixed length = 6.")

    addSection(title: "Phone / Bank Card Auto Formatting", note: "Verifies segmented display formatting while preserving canonical raw value for API submission.")
    addField(title: "Phone auto formatting (allows: digits)", field: FKTextField.make(formatType: .phoneNumber, placeholder: "138 0000 0000"), ruleHint: "Allowed: digits only. Display: 3-4-4.")
    addField(title: "ID card formatting (allows: digits + X/x)", field: FKTextField.make(formatType: .idCard, placeholder: "ID card input"), ruleHint: "Allowed: digits and trailing X/x.")
    addField(title: "Bank card auto formatting (allows: digits)", field: FKTextField.make(formatType: .bankCard, placeholder: "6222 8888 8888 8888"), ruleHint: "Allowed: digits only. Display grouped by 4.")

    addSection(title: "Custom Formatting", note: "Verifies customizable mask style formatting such as serial keys and business-specific grouping patterns.")
    let custom = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[A-Za-z0-9]", maxLength: 12, separator: "-", groupPattern: [4, 4, 4]),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    custom.placeholder = "XXXX-XXXX-XXXX"
    addField(title: "Custom formatting (allows: A-Z, a-z, 0-9)", field: custom, ruleHint: "Allowed: A-Z, a-z, 0-9. Display mask: XXXX-XXXX-XXXX.")

    addSection(title: "Display Value vs Raw Value", note: "Shows why display text is for UI only, while rawText is the value to send to backend.")
    let observeField = FKTextField.make(formatType: .phoneNumber, placeholder: "Observe raw value")
    let rawLabel = UILabel()
    rawLabel.text = "raw/display: -"
    rawLabel.textColor = .secondaryLabel
    rawLabel.font = .preferredFont(forTextStyle: .footnote)
    observeField.onEditingChanged = { raw, formatted in
      rawLabel.text = "raw/display: \(raw) / \(formatted)"
    }
    addField(title: "Raw/display separation", field: observeField, ruleHint: "Allowed: digits only. Label shows raw vs display value.")
    stack.addArrangedSubview(rawLabel)
  }
}

// MARK: - Validation & error

final class FKTextFieldValidationExampleViewController: FKTextFieldExamplePageViewController {
  private let result = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Validation Strategies"
    build()
  }

  private func build() {
    addSection(title: "Trigger Strategy: onChange", note: "Validates continuously while typing. Useful for tight constraints but should be debounced for expensive rules.")
    var onChangeConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .email))
    onChangeConfig.validationPolicy.trigger = .onChange
    onChangeConfig.validationPolicy.debounceInterval = 0.15
    onChangeConfig.inlineMessage.showsErrorMessage = true
    onChangeConfig.placeholder = "onChange email validation"
    let onChangeField = FKTextField(configuration: onChangeConfig)
    onChangeField.onValidationResult = { [weak self] r in self?.result.text = "onChange: \(r.isValid ? "valid" : "invalid")" }
    addField(title: "onChange", field: onChangeField, ruleHint: "Allowed: email characters. Validation triggers on each edit.")

    addSection(title: "Trigger Strategy: onBlur", note: "Validation runs when focus leaves the field. Better for less noisy UX in long forms.")
    var onBlurConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .phoneNumber))
    onBlurConfig.validationPolicy.trigger = .onBlur
    onBlurConfig.inlineMessage.showsErrorMessage = true
    onBlurConfig.placeholder = "onBlur phone validation"
    let onBlurField = FKTextField(configuration: onBlurConfig)
    onBlurField.onValidationResult = { [weak self] r in self?.result.text = "onBlur: \(r.isValid ? "valid" : "invalid")" }
    addField(title: "onBlur", field: onBlurField, ruleHint: "Allowed: digits only. Validation triggers when focus leaves.")

    addSection(title: "Trigger Strategy: onSubmit", note: "Validation only runs on return/submit. Common for server-side dependent constraints.")
    var onSubmitConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, maxLength: 16, minLength: 4, returnKeyBehavior: .dismiss))
    onSubmitConfig.validationPolicy.trigger = .onSubmit
    onSubmitConfig.inlineMessage.showsErrorMessage = true
    onSubmitConfig.placeholder = "onSubmit username validation"
    let onSubmitField = FKTextField(configuration: onSubmitConfig)
    onSubmitField.onDidSubmit = { [weak self] value in
      self?.result.text = "onSubmit: submitted raw = \(value)"
    }
    addField(title: "onSubmit", field: onSubmitField, ruleHint: "Allowed: A-Z, a-z, 0-9. Validation triggers on submit.")

    addSection(title: "Sync + Async Validation", note: "Simulates username availability check with loading indicator. Latest input wins; stale requests are ignored.")
    let loading = UIActivityIndicatorView(style: .medium)
    loading.hidesWhenStopped = true
    var asyncConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, maxLength: 16, minLength: 4))
    asyncConfig.validationPolicy.trigger = .onChange
    asyncConfig.validationPolicy.debounceInterval = 0.25
    asyncConfig.inlineMessage.showsErrorMessage = true
    asyncConfig.messages.helper = "Usernames 'admin' and 'root' are unavailable."
    asyncConfig.placeholder = "username availability check"
    let asyncField = FKTextField(configuration: asyncConfig)
    asyncField.rightView = loading
    asyncField.rightViewMode = .always
    asyncField.setAsyncValidator(
      FKTextFieldAnyAsyncValidator { raw, _, _ in
        guard raw.count >= 4 else { return .init(isValid: false, message: "Minimum 4 characters.") }
        loading.startAnimating()
        try? await Task.sleep(nanoseconds: 800_000_000)
        loading.stopAnimating()
        let forbidden: Set<String> = ["admin", "root", "system"]
        if forbidden.contains(raw.lowercased()) {
          return .init(isValid: false, message: "Username is already taken.")
        }
        return .valid
      }
    )
    asyncField.onDidFailValidation = { [weak self] r in
      self?.result.text = "async: \(r.message ?? "invalid")"
    }
    asyncField.onValidationResult = { [weak self] r in
      if r.isValid {
        self?.result.text = "async: available"
      }
    }
    addField(title: "Sync + async validation", field: asyncField, ruleHint: "Allowed: A-Z, a-z, 0-9. Includes debounced async check.")

    result.textColor = .secondaryLabel
    result.font = .preferredFont(forTextStyle: .footnote)
    result.numberOfLines = 0
    result.text = "Validation result will appear here."
    stack.addArrangedSubview(result)
  }
}

// MARK: - Status gallery

final class FKTextFieldStateGalleryExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Status Gallery"
    build()
  }

  private func build() {
    addSection(title: "Visual State Matrix", note: "Each row locks one state to verify token mapping and state-specific visual clarity.")
    addField(title: "normal", field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Normal"), ruleHint: "Allowed: A-Z, a-z, 0-9.")

    let focused = FKTextField.make(formatType: .alphaNumeric, placeholder: "Focused")
    addField(title: "focused", field: focused, ruleHint: "Allowed: A-Z, a-z, 0-9.")

    let filled = FKTextField.make(formatType: .alphaNumeric, placeholder: "Filled")
    filled.fk_setText("FilledValue")
    addField(title: "filled", field: filled, ruleHint: "Allowed: A-Z, a-z, 0-9.")

    let error = FKTextField.make(formatType: .alphaNumeric, placeholder: "Error")
    error.setError(message: "Forced error state.")
    addField(title: "error", field: error, ruleHint: "Allowed: A-Z, a-z, 0-9. Error style is forced.")

    let success = FKTextField.make(formatType: .alphaNumeric, placeholder: "Success")
    success.setSuccess(message: "Looks good.")
    addField(title: "success", field: success, ruleHint: "Allowed: A-Z, a-z, 0-9. Success style is forced.")

    let disabled = FKTextField.make(formatType: .alphaNumeric, placeholder: "Disabled")
    disabled.isEnabled = false
    disabled.fk_setText("Disabled")
    addField(title: "disabled", field: disabled, ruleHint: "Rule allows A-Z, a-z, 0-9, but control is disabled.")

    var readOnlyConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    readOnlyConfig.isReadOnly = true
    readOnlyConfig.placeholder = "Read-only"
    let readOnly = FKTextField(configuration: readOnlyConfig)
    readOnly.fk_setText("ReadOnly")
    addField(title: "readonly", field: readOnly, ruleHint: "Rule allows A-Z, a-z, 0-9, but control is read-only.")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Showing focused state after view appears keeps visual verification deterministic.
    for case let row as UIStackView in stack.arrangedSubviews {
      for case let field as FKTextField in row.arrangedSubviews where field.placeholder == "Focused" {
        field.becomeFirstResponder()
      }
    }
  }
}

// MARK: - Password

final class FKTextFieldPasswordExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Password"
    build()
  }

  private func build() {
    addSection(title: "Password Visibility + Strength", note: "Allows ASCII input; spaces and emoji are blocked. Icons are smaller, with larger border spacing, and tint follows border state.")

    var visibleConfig = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(
        formatType: .password(minLength: 6, maxLength: 20, validatesStrength: false),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: true
      )
    )
    visibleConfig.accessories.iconSize = 16
    visibleConfig.accessories.horizontalPadding = 12
    visibleConfig.accessories.tintBehavior = .followsBorderState
    let visibleToggle = FKTextField(configuration: visibleConfig)
    visibleToggle.placeholder = "Password visibility toggle"
    addField(title: "Password visibility toggle (ASCII, no spaces/emoji)", field: visibleToggle, ruleHint: "Allowed: ASCII password chars. Blocked: spaces, emoji.")

    var strengthConfig = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(
        formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: true
      )
    )
    strengthConfig.accessories.iconSize = 16
    strengthConfig.accessories.horizontalPadding = 12
    strengthConfig.accessories.tintBehavior = .followsBorderState
    let strengthField = FKTextField(configuration: strengthConfig)
    strengthField.placeholder = "Password strength validation"
    let state = UILabel()
    state.text = "Visibility callback: hidden"
    state.textColor = .secondaryLabel
    state.font = .preferredFont(forTextStyle: .footnote)
    visibleToggle.onPasswordVisibilityToggled = { isVisible in
      state.text = "Visibility callback: \(isVisible ? "visible" : "hidden")"
    }
    addField(title: "Password strength field (ASCII, no spaces/emoji)", field: strengthField, ruleHint: "Allowed: ASCII password chars. Requires stronger composition.")
    stack.addArrangedSubview(state)
  }
}

// MARK: - OTP + counter

final class FKTextFieldOtpCounterExampleViewController: FKTextFieldExamplePageViewController {
  private weak var firstFocusableCodeInput: UIView?
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "OTP & Counter"
    build()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    firstFocusableCodeInput?.becomeFirstResponder()
  }

  private func build() {
    addSection(title: "OTP (FKTextField)", note: "Allows digits only; fixed length 6.")
    let otp = FKTextField(inputRule: FKTextFieldInputRule(formatType: .verificationCode(length: 6, allowsAlphabet: false), autoDismissKeyboardOnComplete: true))
    otp.placeholder = "Enter 6-digit verification code"
    let otpStatus = UILabel()
    otpStatus.text = "OTP callback: waiting for completion"
    otpStatus.textColor = .secondaryLabel
    otpStatus.font = .preferredFont(forTextStyle: .footnote)
    otp.onInputCompleted = { code in
      otpStatus.text = "OTP callback: \(code)"
    }
    addField(title: "OTP (FKTextField)", field: otp, ruleHint: "Allowed: digits only, fixed length = 6.")
    stack.addArrangedSubview(otpStatus)

    addSection(title: "OTP Slot Inputs", note: "Both slot fields allow digits only.")
    var c4 = FKCodeTextField.Configuration(length: 4, slotStyle: .underlines)
    c4.slotSpacing = 12
    let otp4 = FKCodeTextField(configuration: c4)
    otp4.translatesAutoresizingMaskIntoConstraints = false
    otp4.heightAnchor.constraint(equalToConstant: 52).isActive = true
    otp4.onCodeCompleted = { code in
      otpStatus.text = "OTP4 completed: \(code)"
    }
    firstFocusableCodeInput = otp4
    addCustomView(title: "OTP 4 (slot underlines)", view: otp4)

    var c6 = FKCodeTextField.Configuration(length: 6, slotStyle: .boxes)
    c6.slotSpacing = 10
    let otp6 = FKCodeTextField(configuration: c6)
    otp6.textContentType = .oneTimeCode
    otp6.translatesAutoresizingMaskIntoConstraints = false
    otp6.heightAnchor.constraint(equalToConstant: 52).isActive = true
    otp6.onCodeCompleted = { code in
      otpStatus.text = "OTP6 completed: \(code)"
      if code != "123456" {
        otp6.setErrorState(true, shakes: true)
      } else {
        otp6.setErrorState(false, shakes: false)
      }
    }
    addCustomView(title: "OTP 6 (slot boxes, AutoFill)", view: otp6)

    addSection(title: "TextView with Counter", note: "Allows general text input, with max-length enforcement and overflow callback.")
    let tv = FKCountTextView(configuration: FKCountTextView.Configuration(maxLength: 120, showsCounter: true, placeholder: "Enter text (max 120 characters)"))
    tv.font = .systemFont(ofSize: 15)
    let tvStatus = UILabel()
    tvStatus.text = "TextView callback: waiting for input"
    tvStatus.textColor = .secondaryLabel
    tvStatus.font = .preferredFont(forTextStyle: .footnote)
    tv.onTextChanged = { text in
      tvStatus.text = "TextView callback: \(text.count) chars"
    }
    tv.onOverflowAttempt = { _ in
      tvStatus.text = "TextView callback: overflow rejected"
    }
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.heightAnchor.constraint(equalToConstant: 120).isActive = true
    addCustomView(title: "TextView with Counter", view: tv)
    stack.addArrangedSubview(tvStatus)
  }
}

// MARK: - Keyboard interaction

final class FKTextFieldKeyboardExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Keyboard Interaction"
    build()
    registerKeyboardObservers()
  }

  @MainActor deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func build() {
    addSection(title: "Keyboard Auto Offset", note: "Listen to keyboard frame changes and update scrollView insets.")
    for i in 1...8 {
      addField(
        title: "Input \(i)",
        field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Enter item \(i)"),
        ruleHint: "Allowed: A-Z, a-z, 0-9."
      )
    }
    addSection(title: "Tap Blank Area to Dismiss Keyboard", note: "This page already installs a tap gesture to end editing.")
  }

  private func registerKeyboardObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
  }

  @objc private func keyboardWillChangeFrame(_ note: Notification) {
    guard let userInfo = note.userInfo,
          let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
    let keyboardFrame = view.convert(endFrame, from: nil)
    let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
    scrollView.contentInset.bottom = overlap + 12
    scrollView.verticalScrollIndicatorInsets.bottom = overlap + 12
  }
}

// MARK: - Form orchestration

final class FKTextFieldFormExampleViewController: FKTextFieldExamplePageViewController {
  private let statusLabel = UILabel()
  private var fields: [FKTextField] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Form Orchestration"
    build()
  }

  private func build() {
    addSection(title: "Focus Chain + Return Submit", note: "Verifies next focus routing, return-key behavior, and real submit flow with first-error refocus.")
    let username = FKTextField.make(formatType: .alphaNumeric, placeholder: "Username")
    let phone = FKTextField.makePhone(placeholder: "Phone")
    let email = FKTextField.makeEmail(placeholder: "Email")
    let password = FKTextField.makePassword()
    fields = [username, phone, email, password]

    username.updateInputRule(FKTextFieldInputRule(formatType: .alphaNumeric, maxLength: 16, minLength: 4, returnKeyBehavior: .next))
    phone.updateInputRule(FKTextFieldInputRule(formatType: .phoneNumber, returnKeyBehavior: .next))
    email.updateInputRule(FKTextFieldInputRule(formatType: .email, returnKeyBehavior: .next))
    password.updateInputRule(FKTextFieldInputRule(formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true), returnKeyBehavior: .dismiss))

    username.linkNext(phone)
    phone.linkNext(email)
    email.linkNext(password)

    addField(title: "Username", field: username, ruleHint: "Allowed: A-Z, a-z, 0-9. Minimum 4 chars.")
    addField(title: "Phone", field: phone, ruleHint: "Allowed: digits only.")
    addField(title: "Email", field: email, ruleHint: "Allowed: email characters.")
    addField(title: "Password", field: password, ruleHint: "Allowed: password characters. Minimum 8 chars.")

    let submit = UIButton(type: .system)
    submit.setTitle("Submit Form", for: .normal)
    submit.addAction(UIAction { [weak self] _ in
      self?.submitForm()
    }, for: .touchUpInside)
    stack.addArrangedSubview(submit)

    statusLabel.textColor = .secondaryLabel
    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.numberOfLines = 0
    statusLabel.text = "Submit status: waiting."
    stack.addArrangedSubview(statusLabel)
  }

  private func submitForm() {
    let validators: [(FKTextField, (String) -> String?)] = [
      (fields[0], { $0.count >= 4 ? nil : "Username must be at least 4 characters." }),
      (fields[1], { $0.count == 11 ? nil : "Phone must be 11 digits." }),
      (fields[2], { $0.contains("@") ? nil : "Email is invalid." }),
      (fields[3], { $0.count >= 8 ? nil : "Password must be at least 8 characters." }),
    ]
    for (field, rule) in validators {
      if let message = rule(field.rawText) {
        field.setError(message: message)
        field.becomeFirstResponder()
        statusLabel.text = "Submit status: failed -> \(message)"
        return
      } else {
        field.setSuccess(message: "Valid")
      }
    }
    statusLabel.text = "Submit status: success."
    view.endEditing(true)
  }
}

// MARK: - Internationalization and accessibility

final class FKTextFieldI18NExampleViewController: FKTextFieldExamplePageViewController {
  private enum LocaleMode {
    case english
    case chinese
  }

  private var localeMode: LocaleMode = .english
  private let localizedField = FKTextField.make(formatType: .email, placeholder: "Email")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "I18N & Accessibility"
    build()
  }

  private func build() {
    addSection(title: "Locale Switch (EN / ZH)", note: "Verifies localizable placeholder, helper text, and accessibility labels without hardcoded copy.")
    let localeControl = UISegmentedControl(items: ["English", "中文"])
    localeControl.selectedSegmentIndex = 0
    localeControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      self.localeMode = (control.selectedSegmentIndex == 0) ? .english : .chinese
      self.applyLocale()
    }, for: .valueChanged)
    stack.addArrangedSubview(localeControl)

    var config = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .email))
    config.inlineMessage.showsErrorMessage = true
    config.messages.helper = "Use a valid email address."
    config.localization = FKTextFieldLocalization()
    config.placeholder = "Email"
    localizedField.configure(config)
    addField(title: "Localized field", field: localizedField, ruleHint: "Allowed: email characters. Labels and hints switch by locale.")

    addSection(title: "RTL Preview", note: "Forces right-to-left layout direction to verify prefix/suffix and text alignment behavior.")
    let rtl = FKTextField.make(formatType: .phoneNumber, placeholder: "RTL Phone")
    rtl.semanticContentAttribute = .forceRightToLeft
    rtl.textAlignment = .right
    addField(title: "RTL forced phone field", field: rtl, ruleHint: "Allowed: digits only. Layout is forced RTL.")

    addSection(title: "Dynamic Type", note: "Uses preferred text styles and supports larger content sizes without truncation.")
    var dynamicConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    dynamicConfig.style.font = .preferredFont(forTextStyle: .title3)
    dynamicConfig.style.placeholderFont = .preferredFont(forTextStyle: .title3)
    dynamicConfig.floatingTitle = "Dynamic Type Title"
    let dynamicField = FKTextField(configuration: dynamicConfig)
    addField(title: "Large text style field", field: dynamicField, ruleHint: "Allowed: A-Z, a-z, 0-9. Dynamic Type friendly typography.")

    addSection(title: "VoiceOver Key Behavior", note: "Error and success messages are announced. Toggle VoiceOver to verify spoken feedback after validation changes.")
    let voButton = UIButton(type: .system)
    voButton.setTitle("Trigger VoiceOver announcement state", for: .normal)
    voButton.addAction(UIAction { [weak self] _ in
      self?.localizedField.setError(message: self?.localeMode == .english ? "Invalid email format." : "邮箱格式错误。")
    }, for: .touchUpInside)
    stack.addArrangedSubview(voButton)
  }

  private func applyLocale() {
    var config = localizedField.configuration
    switch localeMode {
    case .english:
      config.placeholder = "Email"
      config.messages.helper = "Use a valid email address."
      config.localization = FKTextFieldLocalization(
        clearButtonLabel: "Clear text",
        passwordHiddenLabel: "Show password",
        passwordVisibleLabel: "Hide password",
        counterAnnouncementPrefix: "Character count",
        errorAnnouncementPrefix: "Error",
        successAnnouncementPrefix: "Success"
      )
    case .chinese:
      config.placeholder = "邮箱"
      config.messages.helper = "请输入有效邮箱地址。"
      config.localization = FKTextFieldLocalization(
        clearButtonLabel: "清空输入",
        passwordHiddenLabel: "显示密码",
        passwordVisibleLabel: "隐藏密码",
        counterAnnouncementPrefix: "字符数量",
        errorAnnouncementPrefix: "错误",
        successAnnouncementPrefix: "成功"
      )
    }
    localizedField.configure(config)
  }
}

// MARK: - Theme tokens

final class FKTextFieldThemeExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Theme Tokens"
    build()
  }

  private func build() {
    addSection(title: "Light / Dark Compatibility", note: "Uses semantic colors so states remain distinguishable across interface styles.")
    addField(title: "System semantic style", field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Adaptive style"), ruleHint: "Allowed: A-Z, a-z, 0-9. Colors adapt to Light/Dark.")

    addSection(title: "Token Override", note: "Verifies per-instance token override for border radius, border width, and state colors.")
    var style = FKTextFieldStyle.default
    style.normal.borderColor = .systemTeal
    style.focused.borderColor = .systemIndigo
    style.error.borderColor = .systemRed
    style.success.borderColor = .systemGreen
    style.normal.cornerRadius = 14
    style.focused.borderWidth = 2
    style.error.borderWidth = 2
    style.success.borderWidth = 2
    var config = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric), style: style)
    config.inlineMessage.showsErrorMessage = true
    config.messages.helper = "Type any value and trigger states below."
    let themed = FKTextField(configuration: config)
    addField(title: "Token override field", field: themed, ruleHint: "Allowed: A-Z, a-z, 0-9. State colors and radius are token-driven.")

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.spacing = 8
    actions.distribution = .fillEqually
    let success = UIButton(type: .system)
    success.setTitle("Success", for: .normal)
    success.addAction(UIAction { _ in themed.setSuccess(message: "Validated successfully.") }, for: .touchUpInside)
    let error = UIButton(type: .system)
    error.setTitle("Error", for: .normal)
    error.addAction(UIAction { _ in themed.setError(message: "Validation failed.") }, for: .touchUpInside)
    actions.addArrangedSubview(success)
    actions.addArrangedSubview(error)
    stack.addArrangedSubview(actions)
  }
}

// MARK: - XIB / Storyboard

final class FKTextFieldIBExampleViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "XIB / Storyboard"
    build()
  }

  private func build() {
    addSection(title: "XIB/Storyboard TextField", note: "FKTextField supports init(coder:), so it can be created directly from Interface Builder.")
    let label = UILabel()
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.text = "Do not instantiate NSCoder() manually in runtime example code (it can crash). In real XIB/Storyboard usage, Interface Builder provides a valid coder automatically. FKTextField supports that path via init(coder:)."
    stack.addArrangedSubview(label)

    let storyboardStyle = FKTextField.make(formatType: .alphaNumeric, placeholder: "Simulated IB-created field")
    addField(title: "IB simulation field (allows: A-Z, a-z, 0-9)", field: storyboardStyle, ruleHint: "Allowed: A-Z, a-z, 0-9.")
  }
}

// MARK: - SwiftUI

final class FKTextFieldSwiftUIExampleHostController: UIHostingController<FKTextFieldSwiftUIExampleView> {
  init() {
    super.init(rootView: FKTextFieldSwiftUIExampleView())
    title = "SwiftUI"
  }

  @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder, rootView: FKTextFieldSwiftUIExampleView())
  }
}

struct FKTextFieldSwiftUIExampleView: View {
  @State private var rawText: String = ""

  var body: some View {
    let config = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(formatType: .phoneNumber),
      placeholder: "Enter phone number in SwiftUI"
    )
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("SwiftUI TextField Example")
          .font(.headline)
        Text("Uses FKTextFieldRepresentable from FKUIKit, so UIKit formatting and validation stay consistent.")
          .font(.footnote)
          .foregroundColor(.secondary)
        FKTextFieldRepresentable(rawText: $rawText, configuration: config)
          .frame(height: 44)
        Text("Raw: \(rawText)")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding(16)
    }
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Advanced UI & callbacks

final class FKTextFieldAdvancedCallbacksExampleViewController: FKTextFieldExamplePageViewController {
  private let callbackLogLabel = UILabel()
  private var clearables: [() -> Void] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Advanced UI & Callbacks"
    build()
    configureNavigationActions()
  }

  private func build() {
    addSection(title: "Live Callback Log", note: "Every callback event writes the latest message below.")
    callbackLogLabel.font = .preferredFont(forTextStyle: .footnote)
    callbackLogLabel.textColor = .secondaryLabel
    callbackLogLabel.numberOfLines = 0
    callbackLogLabel.text = "Callback log will be shown here."
    stack.addArrangedSubview(callbackLogLabel)

    addSection(title: "Custom Regex + Callback", note: "Regex-based grouping with realtime didChange and completion callbacks.")
    let customRegex = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[A-Za-z0-9]", maxLength: 12, separator: "-", groupPattern: [4, 4, 4]),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    customRegex.placeholder = "Serial (XXXX-XXXX-XXXX)"
    bind(field: customRegex, name: "CustomRegex")
    registerClearable { [weak customRegex] in customRegex?.clear() }
    addField(title: "Custom regex", field: customRegex, ruleHint: "Allowed: A-Z, a-z, 0-9. Display grouped as XXXX-XXXX-XXXX.")

    addSection(title: "Inline Error + Counter + Validation Feedback", note: "Email field with inline message, counter, and shake-on-invalid.")
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
    addField(title: "Email field", field: email, ruleHint: "Allowed: email characters. Inline message and counter enabled.")

    addSection(title: "Custom Left/Right Accessory", note: "Icons are intentionally smaller with extra horizontal padding. Color/size/spacing/custom views are all configurable by replacing the accessory views.")
    let actionField = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone with left/right icons")
    actionField.clearButtonMode = .whileEditing
    bind(field: actionField, name: "ActionField")
    registerClearable { [weak actionField] in actionField?.clear() }

    let leftIcon = UIImageView(image: UIImage(systemName: "phone.fill"))
    leftIcon.tintColor = .secondaryLabel
    leftIcon.contentMode = .scaleAspectFit
    leftIcon.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
    let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 24))
    leftIcon.center = CGPoint(x: leftContainer.bounds.midX, y: leftContainer.bounds.midY)
    leftContainer.addSubview(leftIcon)
    actionField.leftView = leftContainer
    actionField.leftViewMode = .always

    let sendButton = UIButton(type: .system)
    sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    sendButton.tintColor = .systemBlue
    sendButton.contentHorizontalAlignment = .center
    sendButton.contentVerticalAlignment = .center
    sendButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
    let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 24))
    sendButton.center = CGPoint(x: rightContainer.bounds.midX, y: rightContainer.bounds.midY)
    sendButton.addAction(UIAction { [weak self, weak actionField] _ in
      guard let self, let actionField else { return }
      self.appendLog("Right icon tapped -> raw: \(actionField.rawText)")
    }, for: .touchUpInside)
    rightContainer.addSubview(sendButton)
    actionField.rightView = rightContainer
    actionField.rightViewMode = .always
    addField(title: "Accessory actions", field: actionField, ruleHint: "Allowed: digits only. Accessory buttons are interactive.")
  }

  private func configureNavigationActions() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Clear", image: nil, primaryAction: UIAction { [weak self] _ in self?.clearAll() }, menu: nil),
      UIBarButtonItem(title: "Dismiss", image: nil, primaryAction: UIAction { [weak self] _ in
        self?.view.endEditing(true)
        self?.appendLog("Keyboard dismissed")
      }, menu: nil),
    ]
  }

  private func clearAll() {
    clearables.forEach { $0() }
    appendLog("All inputs cleared")
  }

  private func registerClearable(_ block: @escaping () -> Void) {
    clearables.append(block)
  }

  private func bind(field: FKTextField, name: String) {
    field.onEditingChanged = { [weak self] raw, formatted in
      self?.appendLog("\(name) didChange -> raw: \(raw), formatted: \(formatted)")
    }
    field.onInputCompleted = { [weak self] raw in
      self?.appendLog("\(name) didFinish -> \(raw)")
    }
    field.onValidationResult = { [weak self] result in
      self?.appendLog("\(name) validation -> \(result.isValid ? "valid" : "invalid")")
    }
    field.onDidFailValidation = { [weak self] result in
      if let message = result.message {
        self?.appendLog("\(name) error -> \(message)")
      } else {
        self?.appendLog("\(name) error -> invalid")
      }
    }
  }

  private func appendLog(_ text: String) {
    callbackLogLabel.text = text
  }
}

