import UIKit

/// Entry table for FKTextField demos (mirrors ``FKBadgeExamplesHubViewController`` layout).
final class FKTextFieldExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(title: "Basics", subtitle: "Placeholder, default value, clear, disabled, read-only", controllerType: FKTextFieldExampleBasicsViewController.self),
    Row(title: "Types & formatting", subtitle: "Email, phone, password, amounts, OTP, custom masks", controllerType: FKTextFieldExampleFormatsViewController.self),
    Row(title: "Status gallery", subtitle: "Normal, focused, filled, error, success, disabled, read-only", controllerType: FKTextFieldExampleStatusGalleryViewController.self),
    Row(title: "Validation", subtitle: "onChange / onBlur / onSubmit and async validation", controllerType: FKTextFieldExampleValidationViewController.self),
    Row(title: "Form orchestration", subtitle: "Focus chain, submit, first-error focus", controllerType: FKTextFieldExampleFormViewController.self),
    Row(title: "OTP & counter", subtitle: "FKTextField OTP, FKCodeTextField slots, FKCountTextView", controllerType: FKTextFieldExampleOtpCounterViewController.self),
    Row(title: "Password", subtitle: "Visibility toggle and strength rules", controllerType: FKTextFieldExamplePasswordViewController.self),
    Row(title: "Keyboard & scrolling", subtitle: "Keyboard inset adjustments", controllerType: FKTextFieldExampleKeyboardViewController.self),
    Row(title: "I18N & accessibility", subtitle: "Locale strings, RTL, Dynamic Type, VoiceOver", controllerType: FKTextFieldExampleI18nViewController.self),
    Row(title: "Theme tokens", subtitle: "Semantic colors and per-instance style overrides", controllerType: FKTextFieldExampleThemeViewController.self),
    Row(title: "Interface Builder", subtitle: "Storyboard / XIB usage notes", controllerType: FKTextFieldExampleIBViewController.self),
    Row(title: "SwiftUI", subtitle: "UIViewRepresentable bridge", controllerType: FKTextFieldExampleSwiftUIHostController.self),
    Row(title: "Advanced callbacks", subtitle: "Combined callbacks, counter, shake, accessories", controllerType: FKTextFieldExampleAdvancedCallbacksViewController.self),
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
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let type = rows[indexPath.row].controllerType
    navigationController?.pushViewController(type.init(), animated: true)
  }
}
