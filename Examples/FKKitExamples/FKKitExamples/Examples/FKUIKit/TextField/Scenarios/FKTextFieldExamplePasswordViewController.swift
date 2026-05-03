import UIKit
import FKUIKit

final class FKTextFieldExamplePasswordViewController: FKTextFieldExamplePageViewController {
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
