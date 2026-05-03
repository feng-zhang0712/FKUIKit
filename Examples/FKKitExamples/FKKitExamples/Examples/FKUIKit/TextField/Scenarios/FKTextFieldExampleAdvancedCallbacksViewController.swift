import UIKit
import FKUIKit

final class FKTextFieldExampleAdvancedCallbacksViewController: FKTextFieldExamplePageViewController {
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
