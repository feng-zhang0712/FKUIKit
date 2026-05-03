import UIKit
import FKUIKit

final class FKTextFieldExampleStatusGalleryViewController: FKTextFieldExamplePageViewController {
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
