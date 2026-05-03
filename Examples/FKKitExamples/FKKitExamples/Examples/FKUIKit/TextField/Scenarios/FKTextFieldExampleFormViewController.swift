import UIKit
import FKUIKit

final class FKTextFieldExampleFormViewController: FKTextFieldExamplePageViewController {
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
