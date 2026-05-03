import UIKit
import FKUIKit

/// Dynamic colors and rotation under Auto Layout.
final class FKDividerExampleAdaptiveViewController: FKDividerExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let seg = UISegmentedControl(items: ["System", "Light", "Dark"])
    seg.selectedSegmentIndex = 0
    seg.addAction(UIAction { [weak self] action in
      guard let self, let s = action.sender as? UISegmentedControl else { return }
      switch s.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKDividerExampleSupport.sampleBox()
    let d = FKDivider(configuration: .init(color: .separator))
    d.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(d)
    NSLayoutConstraint.activate([
      d.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      d.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      d.heightAnchor.constraint(equalToConstant: 1),
    ])

    let darkCol = UIStackView(arrangedSubviews: [seg, box])
    darkCol.axis = .vertical
    darkCol.spacing = 8
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Dark mode",
        description: "Dynamic colors resolve again on trait changes.",
        content: darkCol
      )
    )

    let hint = UILabel()
    hint.text = "Rotate the device or simulator to confirm layout."
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0

    let rotBox = FKDividerExampleSupport.sampleBox(height: 120)
    let rot = FKDivider(
      configuration: .init(
        direction: .horizontal,
        showsGradient: true,
        gradientStartColor: .systemPink,
        gradientEndColor: .systemPurple
      )
    )
    rot.translatesAutoresizingMaskIntoConstraints = false
    rotBox.addSubview(rot)
    NSLayoutConstraint.activate([
      rot.leadingAnchor.constraint(equalTo: rotBox.leadingAnchor, constant: 12),
      rot.trailingAnchor.constraint(equalTo: rotBox.trailingAnchor, constant: -12),
      rot.centerYAnchor.constraint(equalTo: rotBox.centerYAnchor),
      rot.heightAnchor.constraint(equalToConstant: 1),
    ])
    let rotCol = UIStackView(arrangedSubviews: [hint, rotBox])
    rotCol.axis = .vertical
    rotCol.spacing = 8
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Rotation", description: "Constraints keep the stroke centered after bounds change.", content: rotCol)
    )
  }
}
