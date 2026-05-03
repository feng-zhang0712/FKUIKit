import UIKit
import FKUIKit

final class FKTextFieldExampleI18nViewController: FKTextFieldExamplePageViewController {
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
