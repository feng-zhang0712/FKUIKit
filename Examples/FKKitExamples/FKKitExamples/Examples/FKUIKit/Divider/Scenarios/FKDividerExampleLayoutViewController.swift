import UIKit
import FKUIKit

/// `fk_addDivider`, global defaults, and Interface Builder–style properties.
final class FKDividerExampleLayoutViewController: FKDividerExampleBaseViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let pinTop = FKDividerExampleSupport.sampleBox(height: 64)
    pinTop.fk_addDivider(at: .top, margin: 16)
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Pin to top", description: "`fk_addDivider(at: .top, margin:)`.", content: pinTop)
    )

    let pinBottom = FKDividerExampleSupport.sampleBox(height: 64)
    pinBottom.fk_addDivider(at: .bottom, margin: 16)
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(title: "Pin to bottom", description: "`fk_addDivider(at: .bottom, margin:)`.", content: pinBottom)
    )

    let pinSides = FKDividerExampleSupport.sampleBox(height: 84)
    pinSides.fk_addDivider(at: .leading, margin: 12)
    pinSides.fk_addDivider(at: .trailing, margin: 12)
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Pin to leading / trailing",
        description: "Vertical hairlines on semantic edges (RTL-aware).",
        content: pinSides
      )
    )

    let apply = UIButton(type: .system)
    apply.setTitle("Apply global default", for: .normal)
    apply.addAction(UIAction { _ in
      var g = FKDividerConfiguration()
      g.color = .systemOrange
      g.isPixelPerfect = false
      g.thickness = 2
      FKDivider.defaultConfiguration = g
    }, for: .touchUpInside)

    let preview = UIButton(type: .system)
    preview.setTitle("Push another divider using current default", for: .normal)
    preview.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let box = FKDividerExampleSupport.sampleBox(height: 40)
      let d = FKDivider()
      d.translatesAutoresizingMaskIntoConstraints = false
      box.addSubview(d)
      NSLayoutConstraint.activate([
        d.leadingAnchor.constraint(equalTo: box.leadingAnchor),
        d.trailingAnchor.constraint(equalTo: box.trailingAnchor),
        d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        d.heightAnchor.constraint(equalToConstant: 2),
      ])
      self.stack.addArrangedSubview(box)
    }, for: .touchUpInside)

    let globalCol = UIStackView(arrangedSubviews: [apply, preview])
    globalCol.axis = .vertical
    globalCol.spacing = 8
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Global default",
        description: "Assign `FKDivider.defaultConfiguration` (similar to other FKUIKit components). New `FKDivider()` copies the struct at init time.",
        content: globalCol
      )
    )

    let ibBox = FKDividerExampleSupport.sampleBox(height: 64)
    let ib = FKDivider()
    ib.ibDirection = 0
    ib.ibLineStyle = 1
    ib.ibDashLength = 8
    ib.ibDashGap = 3
    ib.ibInsetLeft = 20
    ib.ibInsetRight = 20
    ib.ibShowsGradient = true
    ib.ibGradientStartColor = .systemIndigo
    ib.ibGradientEndColor = .systemCyan
    ib.translatesAutoresizingMaskIntoConstraints = false
    ibBox.addSubview(ib)
    NSLayoutConstraint.activate([
      ib.leadingAnchor.constraint(equalTo: ibBox.leadingAnchor),
      ib.trailingAnchor.constraint(equalTo: ibBox.trailingAnchor),
      ib.centerYAnchor.constraint(equalTo: ibBox.centerYAnchor),
      ib.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(
      FKDividerExampleSupport.card(
        title: "Interface Builder bridge",
        description: "Set the view class to `FKDivider` in a storyboard and use `ib*` inspectables, or assign them in code as shown.",
        content: ibBox
      )
    )
  }
}
