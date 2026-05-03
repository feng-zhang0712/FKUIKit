import UIKit
import FKUIKit

final class FKTextFieldExampleThemeViewController: FKTextFieldExamplePageViewController {
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
