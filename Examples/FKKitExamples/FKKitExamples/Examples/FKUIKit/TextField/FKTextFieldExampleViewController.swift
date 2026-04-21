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
    Item(title: "Basics & Style", subtitle: "Base replacement, insets, placeholder, underline, dark mode, global defaults", make: { FKTextFieldBasicStyleDemoViewController() }),
    Item(title: "Formatting & Filtering", subtitle: "Phone/bank/custom formatting + numeric/chinese/regex filtering", make: { FKTextFieldFormatFilterDemoViewController() }),
    Item(title: "Validation & Error State", subtitle: "Phone/email/custom validation and explicit error feedback", make: { FKTextFieldValidationDemoViewController() }),
    Item(title: "Password", subtitle: "Visibility toggle and strength validation", make: { FKTextFieldPasswordDemoViewController() }),
    Item(title: "OTP & Counter Input", subtitle: "OTP(FKTextField), OTP4/OTP6 slots, TextView with counter", make: { FKTextFieldOtpCounterDemoViewController() }),
    Item(title: "Keyboard Interaction", subtitle: "Keyboard offset handling and tap-to-dismiss", make: { FKTextFieldKeyboardDemoViewController() }),
    Item(title: "Advanced UI & Callbacks", subtitle: "Custom accessories, inline counter, callback logs, and action examples", make: { FKTextFieldAdvancedCallbacksDemoViewController() }),
    Item(title: "XIB / Storyboard", subtitle: "Demonstrates Interface Builder creation entry", make: { FKTextFieldIBDemoViewController() }),
    Item(title: "SwiftUI", subtitle: "UIViewRepresentable wrapper for FKTextField", make: { FKTextFieldSwiftUIDemoHostController() }),
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

class FKTextFieldDemoPageViewController: UIViewController {
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

  func addField(title: String, field: FKTextField) {
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

final class FKTextFieldBasicStyleDemoViewController: FKTextFieldDemoPageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics & Style"
    build()
  }

  private func build() {
    addSection(title: "Basic Field (UITextField Replacement)", note: "Alphanumeric only by default in this sample: allows ASCII letters and digits; blocks punctuation and spaces.")
    addField(title: "Basic (allows: A-Z, a-z, 0-9)", field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Basic input"))

    addSection(title: "Any-Character Input", note: "This field allows all characters, including punctuation, spaces, emoji, and symbols.")
    let anyCharField = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[\\s\\S]", maxLength: nil, separator: nil, groupPattern: []),
        allowedInput: .any,
        allowsWhitespace: true,
        allowsEmoji: true,
        allowsSpecialCharacters: true
      )
    )
    anyCharField.placeholder = "Try: abc ._+- 中文 😄 123"
    addField(title: "Any character input (allows all)", field: anyCharField)

    addSection(title: "Custom Insets + Placeholder Style", note: "Input rule here is alphanumeric (ASCII letters/digits). Use layout.contentInsets and attributedPlaceholder for visual tuning.")
    var config = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    config.layout.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    config.attributedPlaceholder = NSAttributedString(
      string: "Enter username",
      attributes: [.foregroundColor: UIColor.systemOrange, .font: UIFont.italicSystemFont(ofSize: 14)]
    )
    addField(title: "Padding + Placeholder", field: FKTextField(configuration: config))

    addSection(title: "Underline Style Field", note: "Input rule here is alphanumeric (ASCII letters/digits). Set decoration.mode to underline to switch from border mode.")
    var underlineConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .alphaNumeric))
    underlineConfig.decoration.mode = .underline(thickness: 2, insets: UIEdgeInsets(top: 0, left: 8, bottom: 1, right: 8))
    underlineConfig.placeholder = "Underline field"
    addField(title: "Underline", field: FKTextField(configuration: underlineConfig))

    addSection(title: "Global Style + Dark Mode", note: "Input rule here is alphanumeric (ASCII letters/digits). Global defaults and dynamic system colors keep the control dark-mode friendly.")
    FKTextFieldManager.shared.configureDefaultStyle { style in
      style.normal.backgroundColor = .secondarySystemBackground
      style.normal.borderColor = .separator
      style.focused.borderColor = .systemBlue
      style.placeholderColor = .tertiaryLabel
    }
    addField(title: "Global style field", field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Uses global defaults"))
  }
}

// MARK: - Formatting & filtering

final class FKTextFieldFormatFilterDemoViewController: FKTextFieldDemoPageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Formatting & Filtering"
    build()
  }

  private func build() {
    addSection(title: "Phone / Bank Card Auto Formatting", note: "Phone/Bank allow digits only; ID allows digits plus trailing X/x for checksum.")
    addField(title: "Phone auto formatting (allows: digits)", field: FKTextField.make(formatType: .phoneNumber, placeholder: "138 0000 0000"))
    addField(title: "ID card formatting (allows: digits + X/x)", field: FKTextField.make(formatType: .idCard, placeholder: "ID card input"))
    addField(title: "Bank card auto formatting (allows: digits)", field: FKTextField.make(formatType: .bankCard, placeholder: "6222 8888 8888 8888"))

    addSection(title: "Custom Formatting", note: "Allows only A-Z/a-z/0-9 via regex, then groups as XXXX-XXXX-XXXX.")
    let custom = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[A-Za-z0-9]", maxLength: 12, separator: "-", groupPattern: [4, 4, 4]),
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false
      )
    )
    custom.placeholder = "XXXX-XXXX-XXXX"
    addField(title: "Custom formatting (allows: A-Z, a-z, 0-9)", field: custom)

    addSection(title: "Input Filtering", note: "Each field below explicitly states allowed characters.")
    addField(title: "Numeric only (allows: digits)", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .numeric, allowedInput: .numeric)))
    addField(title: "Chinese only (allows: CJK ideographs)", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .custom(regex: "[\\u{3400}-\\u{9FFF}]", maxLength: nil, separator: nil, groupPattern: []), allowedInput: .chinese)))
    addField(title: "Regex filter (allows: uppercase A-Z)", field: FKTextField(inputRule: FKTextFieldInputRule(formatType: .custom(regex: "[A-Z]", maxLength: nil, separator: nil, groupPattern: []), allowedInput: .regex("[A-Z]"))))
  }
}

// MARK: - Validation & error

final class FKTextFieldValidationDemoViewController: FKTextFieldDemoPageViewController {
  private let result = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Validation & Error"
    build()
  }

  private func build() {
    addSection(title: "Phone / Email / Custom Validation", note: "Phone: digits only. Email: common email characters. Custom rule: letters/numbers/underscore.")

    let phone = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone validation")
    phone.onValidationResult = { [weak self] r in self?.result.text = "Phone: \(r.isValid ? "valid" : "invalid")" }
    addField(title: "Phone validation field (allows: digits)", field: phone)

    var emailConfig = FKTextFieldConfiguration(inputRule: FKTextFieldInputRule(formatType: .email))
    emailConfig.inlineMessage.showsErrorMessage = true
    emailConfig.placeholder = "Email validation"
    let email = FKTextField(configuration: emailConfig)
    email.onValidationResult = { [weak self] r in self?.result.text = "Email: \(r.isValid ? "valid" : "invalid")" }
    addField(title: "Email validation field (allows: email characters)", field: email)

    let customRule = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .custom(regex: "[A-Za-z0-9_]", maxLength: 16, separator: nil, groupPattern: []),
        allowedInput: .regex("[A-Za-z0-9_]")
      )
    )
    customRule.placeholder = "Username (letters/numbers/underscore)"
    customRule.onValidationResult = { [weak self] r in self?.result.text = "Custom rule: \(r.isValid ? "valid" : "invalid")" }
    addField(title: "Custom validation field (allows: A-Z, a-z, 0-9, _)", field: customRule)

    addSection(title: "Error State & Error Message", note: "Call setError and shakeForValidationFailure for explicit submit-time feedback.")
    let submit = UIButton(type: .system)
    submit.setTitle("Trigger error state", for: .normal)
    submit.addAction(UIAction { _ in
      customRule.setError(message: "Username format is invalid.")
      customRule.shakeForValidationFailure()
    }, for: .touchUpInside)
    stack.addArrangedSubview(submit)

    result.textColor = .secondaryLabel
    result.font = .preferredFont(forTextStyle: .footnote)
    result.numberOfLines = 0
    result.text = "Validation result will appear here."
    stack.addArrangedSubview(result)
  }
}

// MARK: - Password

final class FKTextFieldPasswordDemoViewController: FKTextFieldDemoPageViewController {
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
    addField(title: "Password visibility toggle (ASCII, no spaces/emoji)", field: visibleToggle)

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
    addField(title: "Password strength field (ASCII, no spaces/emoji)", field: strengthField)
    stack.addArrangedSubview(state)
  }
}

// MARK: - OTP + counter

final class FKTextFieldOtpCounterDemoViewController: FKTextFieldDemoPageViewController {
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
    addField(title: "OTP (FKTextField)", field: otp)
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

final class FKTextFieldKeyboardDemoViewController: FKTextFieldDemoPageViewController {
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
      addField(title: "Input \(i)", field: FKTextField.make(formatType: .alphaNumeric, placeholder: "Enter item \(i)"))
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

// MARK: - XIB / Storyboard

final class FKTextFieldIBDemoViewController: FKTextFieldDemoPageViewController {
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
    label.text = "Do not instantiate NSCoder() manually in runtime demo code (it can crash). In real XIB/Storyboard usage, Interface Builder provides a valid coder automatically. FKTextField supports that path via init(coder:)."
    stack.addArrangedSubview(label)

    let storyboardStyle = FKTextField.make(formatType: .alphaNumeric, placeholder: "Simulated IB-created field")
    addField(title: "IB simulation field (allows: A-Z, a-z, 0-9)", field: storyboardStyle)
  }
}

// MARK: - SwiftUI

final class FKTextFieldSwiftUIDemoHostController: UIHostingController<FKTextFieldSwiftUIDemoView> {
  init() {
    super.init(rootView: FKTextFieldSwiftUIDemoView())
    title = "SwiftUI"
  }

  @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder, rootView: FKTextFieldSwiftUIDemoView())
  }
}

struct FKTextFieldSwiftUIDemoView: View {
  @State private var text: String = ""

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("SwiftUI TextField Demo")
          .font(.headline)
        Text("Wrap FKTextField using UIViewRepresentable to preserve formatting and validation features.")
          .font(.footnote)
          .foregroundColor(.secondary)
        FKTextFieldRepresentable(text: $text, placeholder: "Enter phone number in SwiftUI")
          .frame(height: 44)
        Text("Raw: \(text)")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
      .padding(16)
    }
    .background(Color(.systemGroupedBackground))
  }
}

struct FKTextFieldRepresentable: UIViewRepresentable {
  @Binding var text: String
  let placeholder: String

  func makeUIView(context: Context) -> FKTextField {
    let field = FKTextField.make(formatType: .phoneNumber, placeholder: placeholder)
    field.onTextDidChange = { raw, _ in
      context.coordinator.parent.text = raw
    }
    return field
  }

  func updateUIView(_ uiView: FKTextField, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  final class Coordinator {
    var parent: FKTextFieldRepresentable
    init(parent: FKTextFieldRepresentable) {
      self.parent = parent
    }
  }
}

// MARK: - Advanced UI & callbacks

final class FKTextFieldAdvancedCallbacksDemoViewController: FKTextFieldDemoPageViewController {
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
    addField(title: "Custom regex", field: customRegex)

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
    addField(title: "Email field", field: email)

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
    addField(title: "Accessory actions", field: actionField)
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

  private func appendLog(_ text: String) {
    callbackLogLabel.text = text
  }
}

