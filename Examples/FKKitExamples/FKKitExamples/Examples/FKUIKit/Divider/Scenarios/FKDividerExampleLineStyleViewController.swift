import UIKit
import FKUIKit

/// Dashed patterns and gradient strokes.
final class FKDividerExampleLineStyleViewController: FKDividerExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    var dashed = FKDividerConfiguration()
    dashed.lineStyle = .dashed
    let dashedBox = FKDividerExampleSupport.sampleBox()
    let dashedDivider = FKDivider(configuration: dashed)
    dashedDivider.translatesAutoresizingMaskIntoConstraints = false
    dashedBox.addSubview(dashedDivider)
    NSLayoutConstraint.activate([
      dashedDivider.leadingAnchor.constraint(equalTo: dashedBox.leadingAnchor),
      dashedDivider.trailingAnchor.constraint(equalTo: dashedBox.trailingAnchor),
      dashedDivider.centerYAnchor.constraint(equalTo: dashedBox.centerYAnchor),
      dashedDivider.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Dashed", description: "Toggle `lineStyle` to `.dashed`.", content: dashedBox)
    )

    let patternColumn = UIStackView()
    patternColumn.axis = .vertical
    patternColumn.spacing = 10
    [[CGFloat(2), 2], [6, 3], [10, 4]].forEach { pattern in
      let row = FKDividerExampleSupport.sampleBox(height: 32)
      var c = FKDividerConfiguration()
      c.lineStyle = .dashed
      c.dashPattern = pattern
      let d = FKDivider(configuration: c)
      d.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview(d)
      NSLayoutConstraint.activate([
        d.leadingAnchor.constraint(equalTo: row.leadingAnchor),
        d.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        d.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        d.heightAnchor.constraint(equalToConstant: 1),
      ])
      patternColumn.addArrangedSubview(row)
    }
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Dash patterns", description: "`dashPattern` is `[CGFloat]` stroke and gap lengths.", content: patternColumn)
    )

    let gradientColumn = UIStackView()
    gradientColumn.axis = .vertical
    gradientColumn.spacing = 10

    let hBox = FKDividerExampleSupport.sampleBox(height: 36)
    var hc = FKDividerConfiguration()
    hc.showsGradient = true
    hc.gradientDirection = .horizontal
    hc.gradientStartColor = .systemPink
    hc.gradientEndColor = .systemPurple
    let hd = FKDivider(configuration: hc)
    hd.translatesAutoresizingMaskIntoConstraints = false
    hBox.addSubview(hd)
    NSLayoutConstraint.activate([
      hd.leadingAnchor.constraint(equalTo: hBox.leadingAnchor),
      hd.trailingAnchor.constraint(equalTo: hBox.trailingAnchor),
      hd.centerYAnchor.constraint(equalTo: hBox.centerYAnchor),
      hd.heightAnchor.constraint(equalToConstant: 1),
    ])
    gradientColumn.addArrangedSubview(hBox)

    let vBox = FKDividerExampleSupport.sampleBox(height: 88)
    var vc = FKDividerConfiguration(direction: .vertical)
    vc.showsGradient = true
    vc.gradientDirection = .vertical
    vc.gradientStartColor = .systemBlue
    vc.gradientEndColor = .systemTeal
    let vd = FKDivider(configuration: vc)
    vd.translatesAutoresizingMaskIntoConstraints = false
    vBox.addSubview(vd)
    NSLayoutConstraint.activate([
      vd.topAnchor.constraint(equalTo: vBox.topAnchor),
      vd.bottomAnchor.constraint(equalTo: vBox.bottomAnchor),
      vd.centerXAnchor.constraint(equalTo: vBox.centerXAnchor),
      vd.widthAnchor.constraint(equalToConstant: 1),
    ])
    gradientColumn.addArrangedSubview(vBox)

    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Gradients",
        description: "Gradient is masked by the same stroke path as solid lines; horizontal gradient follows layout direction.",
        content: gradientColumn
      )
    )
  }
}
