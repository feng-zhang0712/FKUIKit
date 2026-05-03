import UIKit
import FKUIKit

final class FKTextFieldExampleFormatsViewController: FKTextFieldExamplePageViewController {
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
