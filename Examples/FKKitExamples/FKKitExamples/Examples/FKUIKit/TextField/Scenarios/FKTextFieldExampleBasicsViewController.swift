import UIKit
import FKUIKit

final class FKTextFieldExampleBasicsViewController: FKTextFieldExamplePageViewController {
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
