import UIKit
import FKUIKit

final class FKTextFieldExampleValidationViewController: FKTextFieldExamplePageViewController {
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
