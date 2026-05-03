import UIKit
import FKUIKit

final class FKTextFieldExampleIBViewController: FKTextFieldExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "XIB / Storyboard"
    build()
  }

  private func build() {
    addSection(title: "XIB/Storyboard TextField", note: "FKTextField supports init(coder:), so it can be created directly from Interface Builder.")
    let label = UILabel()
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.text = "Do not instantiate NSCoder() manually in runtime example code (it can crash). In real XIB/Storyboard usage, Interface Builder provides a valid coder automatically. FKTextField supports that path via init(coder:)."
    stack.addArrangedSubview(label)

    let storyboardStyle = FKTextField.make(formatType: .alphaNumeric, placeholder: "Simulated IB-created field")
    addField(title: "IB simulation field (allows: A-Z, a-z, 0-9)", field: storyboardStyle, ruleHint: "Allowed: A-Z, a-z, 0-9.")
  }
}
