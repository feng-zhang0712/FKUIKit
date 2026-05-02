import UIKit
import FKUIKit

final class FKBadgeExampleAnchorsViewController: FKBadgeExampleScrollViewController {

  private let anchorDemoHost = UIView()
  private let anchorDemoTarget = UIView()

  private let cornerTL = UIView()
  private let cornerTR = UIView()
  private let cornerBL = UIView()
  private let cornerBR = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    installScrollRootChrome()
    buildAnchorInteractiveSection()
    buildFourCornersSection()
    buildOffsetSection()
  }

  private func buildAnchorInteractiveSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Anchors: corners + center (single target)")

    anchorDemoHost.backgroundColor = .secondarySystemFill
    anchorDemoHost.layer.cornerRadius = 12
    anchorDemoHost.translatesAutoresizingMaskIntoConstraints = false

    anchorDemoTarget.backgroundColor = .systemBlue.withAlphaComponent(0.25)
    anchorDemoTarget.layer.cornerRadius = 8
    anchorDemoTarget.translatesAutoresizingMaskIntoConstraints = false
    anchorDemoHost.addSubview(anchorDemoTarget)

    let seg = UISegmentedControl(items: ["TR", "TL", "BR", "BL", "C"])
    let anchors: [(String, FKBadgeAnchor)] = [
      ("TR", .topTrailing),
      ("TL", .topLeading),
      ("BR", .bottomTrailing),
      ("BL", .bottomLeading),
      ("C", .center),
    ]
    seg.selectedSegmentIndex = 0
    seg.addAction(UIAction { [weak self] a in
      guard let self, let c = a.sender as? UISegmentedControl else { return }
      let idx = c.selectedSegmentIndex
      guard idx >= 0, idx < anchors.count else { return }
      FKBadgeExampleSupport.applyAnchor(anchors[idx].1, to: self.anchorDemoTarget)
    }, for: .valueChanged)

    NSLayoutConstraint.activate([
      anchorDemoHost.heightAnchor.constraint(equalToConstant: 140),
      anchorDemoTarget.centerXAnchor.constraint(equalTo: anchorDemoHost.centerXAnchor),
      anchorDemoTarget.centerYAnchor.constraint(equalTo: anchorDemoHost.centerYAnchor),
      anchorDemoTarget.widthAnchor.constraint(equalToConstant: 100),
      anchorDemoTarget.heightAnchor.constraint(equalToConstant: 72),
    ])

    anchorDemoTarget.fk_badge.showCount(7)
    FKBadgeExampleSupport.applyAnchor(.topTrailing, to: anchorDemoTarget)

    box.addArrangedSubview(seg)
    box.addArrangedSubview(anchorDemoHost)
    contentStack.addArrangedSubview(box)
  }

  private func buildFourCornersSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Four corners at once")

    let grid = UIStackView()
    grid.axis = .vertical
    grid.spacing = 12

    let topRow = UIStackView()
    topRow.axis = .horizontal
    topRow.spacing = 12
    topRow.distribution = .fillEqually

    let botRow = UIStackView()
    botRow.axis = .horizontal
    botRow.spacing = 12
    botRow.distribution = .fillEqually

    FKBadgeExampleSupport.styleCornerHost(cornerTL)
    FKBadgeExampleSupport.styleCornerHost(cornerTR)
    FKBadgeExampleSupport.styleCornerHost(cornerBL)
    FKBadgeExampleSupport.styleCornerHost(cornerBR)

    cornerTL.fk_badge.setAnchor(.topLeading, offset: UIOffset(horizontal: 4, vertical: 4))
    cornerTL.fk_badge.showText("TL")

    cornerTR.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -4, vertical: 4))
    cornerTR.fk_badge.showText("TR")

    cornerBL.fk_badge.setAnchor(.bottomLeading, offset: UIOffset(horizontal: 4, vertical: -4))
    cornerBL.fk_badge.showText("BL")

    cornerBR.fk_badge.setAnchor(.bottomTrailing, offset: UIOffset(horizontal: -4, vertical: -4))
    cornerBR.fk_badge.showText("BR")

    topRow.addArrangedSubview(cornerTL)
    topRow.addArrangedSubview(cornerTR)
    botRow.addArrangedSubview(cornerBL)
    botRow.addArrangedSubview(cornerBR)

    [cornerTL, cornerTR, cornerBL, cornerBR].forEach { v in
      v.heightAnchor.constraint(equalTo: v.widthAnchor).isActive = true
    }

    grid.addArrangedSubview(topRow)
    grid.addArrangedSubview(botRow)
    box.addArrangedSubview(grid)
    contentStack.addArrangedSubview(box)
  }

  private func buildOffsetSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Offset: slider")

    let host = UIView()
    host.backgroundColor = .secondarySystemFill
    host.layer.cornerRadius = 12
    host.translatesAutoresizingMaskIntoConstraints = false

    let target = UIView()
    target.backgroundColor = .systemOrange.withAlphaComponent(0.35)
    target.layer.cornerRadius = 8
    target.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(target)

    let slider = UISlider()
    slider.minimumValue = -24
    slider.maximumValue = 24
    slider.value = -6
    slider.addAction(UIAction { [weak target] a in
      guard let s = a.sender as? UISlider, let target else { return }
      let x = CGFloat(s.value)
      target.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: x, vertical: x * 0.5))
    }, for: .valueChanged)

    target.fk_badge.showCount(3)
    target.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -6, vertical: 3))

    NSLayoutConstraint.activate([
      host.heightAnchor.constraint(equalToConstant: 100),
      target.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      target.centerYAnchor.constraint(equalTo: host.centerYAnchor),
      target.widthAnchor.constraint(equalToConstant: 120),
      target.heightAnchor.constraint(equalToConstant: 56),
    ])

    let cap = UILabel()
    cap.font = .preferredFont(forTextStyle: .caption1)
    cap.textColor = .secondaryLabel
    cap.text = "Slider drives horizontal offset; vertical follows at 0.5×."

    box.addArrangedSubview(slider)
    box.addArrangedSubview(host)
    box.addArrangedSubview(cap)
    contentStack.addArrangedSubview(box)
  }
}
