import UIKit
import FKUIKit

/// Horizontal / vertical lines, hairline mode, insets, logical thickness, and solid colors.
final class FKDividerExampleBasicsViewController: FKDividerExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let horizontalBox = FKDividerExampleSupport.sampleBox()
    let horizontal = FKDivider(configuration: .init(direction: .horizontal, lineStyle: .solid))
    horizontal.translatesAutoresizingMaskIntoConstraints = false
    horizontalBox.addSubview(horizontal)
    NSLayoutConstraint.activate([
      horizontal.leadingAnchor.constraint(equalTo: horizontalBox.leadingAnchor),
      horizontal.trailingAnchor.constraint(equalTo: horizontalBox.trailingAnchor),
      horizontal.centerYAnchor.constraint(equalTo: horizontalBox.centerYAnchor),
      horizontal.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Horizontal solid", description: "Default list-style separator.", content: horizontalBox)
    )

    let verticalBox = FKDividerExampleSupport.sampleBox(height: 80)
    let vertical = FKDivider(configuration: .init(direction: .vertical))
    vertical.translatesAutoresizingMaskIntoConstraints = false
    verticalBox.addSubview(vertical)
    NSLayoutConstraint.activate([
      vertical.topAnchor.constraint(equalTo: verticalBox.topAnchor),
      vertical.bottomAnchor.constraint(equalTo: verticalBox.bottomAnchor),
      vertical.centerXAnchor.constraint(equalTo: verticalBox.centerXAnchor),
      vertical.widthAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Vertical solid", description: "Column separator between regions.", content: verticalBox)
    )

    var hairlineConfig = FKDividerConfiguration()
    hairlineConfig.isPixelPerfect = true
    hairlineConfig.thickness = 3
    let hairlineBox = FKDividerExampleSupport.sampleBox()
    let hairline = FKDivider(configuration: hairlineConfig)
    hairline.translatesAutoresizingMaskIntoConstraints = false
    hairlineBox.addSubview(hairline)
    NSLayoutConstraint.activate([
      hairline.leadingAnchor.constraint(equalTo: hairlineBox.leadingAnchor),
      hairline.trailingAnchor.constraint(equalTo: hairlineBox.trailingAnchor),
      hairline.centerYAnchor.constraint(equalTo: hairlineBox.centerYAnchor),
      hairline.heightAnchor.constraint(equalToConstant: 3),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Hairline (pixel-aligned)",
        description: "`isPixelPerfect` uses one physical pixel regardless of the logical `thickness` value.",
        content: hairlineBox
      )
    )

    var insetConfig = FKDividerConfiguration()
    insetConfig.contentInsets = .init(top: 0, left: 28, bottom: 0, right: 28)
    let insetBox = FKDividerExampleSupport.sampleBox()
    let insetDivider = FKDivider(configuration: insetConfig)
    insetDivider.translatesAutoresizingMaskIntoConstraints = false
    insetBox.addSubview(insetDivider)
    NSLayoutConstraint.activate([
      insetDivider.leadingAnchor.constraint(equalTo: insetBox.leadingAnchor),
      insetDivider.trailingAnchor.constraint(equalTo: insetBox.trailingAnchor),
      insetDivider.centerYAnchor.constraint(equalTo: insetBox.centerYAnchor),
      insetDivider.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Indented line", description: "`contentInsets` shorten the stroke inside the bounds.", content: insetBox)
    )

    let thicknessColumn = UIStackView()
    thicknessColumn.axis = .vertical
    thicknessColumn.spacing = 10
    [1.0, 2.0, 4.0].forEach { w in
      let row = FKDividerExampleSupport.sampleBox(height: 36)
      var c = FKDividerConfiguration()
      c.isPixelPerfect = false
      c.thickness = w
      let d = FKDivider(configuration: c)
      d.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview(d)
      NSLayoutConstraint.activate([
        d.leadingAnchor.constraint(equalTo: row.leadingAnchor),
        d.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        d.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        d.heightAnchor.constraint(equalToConstant: w),
      ])
      thicknessColumn.addArrangedSubview(row)
    }
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Logical thickness", description: "Turn off `isPixelPerfect` to honor `thickness` in points.", content: thicknessColumn)
    )

    let colorColumn = UIStackView()
    colorColumn.axis = .vertical
    colorColumn.spacing = 10
    [UIColor.systemRed, .systemBlue, .systemGreen].forEach { color in
      let row = FKDividerExampleSupport.sampleBox(height: 32)
      var c = FKDividerConfiguration()
      c.color = color
      let d = FKDivider(configuration: c)
      d.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview(d)
      NSLayoutConstraint.activate([
        d.leadingAnchor.constraint(equalTo: row.leadingAnchor),
        d.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        d.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        d.heightAnchor.constraint(equalToConstant: 1),
      ])
      colorColumn.addArrangedSubview(row)
    }
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Colors", description: "Works with semantic and fixed colors.", content: colorColumn)
    )
  }
}
