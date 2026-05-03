import UIKit
import FKUIKit

final class FKBadgeExampleBasicsViewController: FKBadgeExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    installScrollRootChrome()

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.text = "The badge is a sibling in the superview so the target's clips and hit-testing stay unchanged."
    hint.translatesAutoresizingMaskIntoConstraints = false
    contentStack.addArrangedSubview(hint)

    buildInterfaceStyleSection()
    buildBasicsSection()
    buildNumericSection()
    buildTextSection()
  }

  private func buildInterfaceStyleSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Interface style: light / dark (dynamic colors)")
    let seg = UISegmentedControl(items: ["System", "Light", "Dark"])
    seg.selectedSegmentIndex = 0
    seg.addAction(UIAction { [weak self] a in
      guard let self, let s = a.sender as? UISegmentedControl else { return }
      switch s.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)
    box.addArrangedSubview(seg)
    contentStack.addArrangedSubview(box)
  }

  private func buildBasicsSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Dot only")
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 12
    row.alignment = .center

    let target = FKBadgeExampleSupport.makeChipTarget()
    target.fk_badge.showDot(animation: .pop())

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.text = "showDot() / showText(\"\")"
    note.numberOfLines = 0

    row.addArrangedSubview(target)
    row.addArrangedSubview(note)
    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)
  }

  private func buildNumericSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Numeric: 1–99, 99+, custom cap")

    let g1 = UIStackView()
    g1.axis = .horizontal
    g1.spacing = 8
    g1.alignment = .center
    g1.distribution = .equalSpacing
    [1, 42, 99].forEach { n in
      g1.addArrangedSubview(FKBadgeExampleSupport.staticNumberChip(n))
    }

    let g2 = UIStackView()
    g2.axis = .horizontal
    g2.spacing = 8
    g2.alignment = .center
    g2.distribution = .equalSpacing
    [100, 999].forEach { n in
      g2.addArrangedSubview(FKBadgeExampleSupport.staticNumberChip(n))
    }

    let customBox = UIStackView()
    customBox.axis = .horizontal
    customBox.spacing = 12
    customBox.alignment = .center
    let t = FKBadgeExampleSupport.makeChipTarget()
    t.fk_badge.configuration.maxDisplayCount = 199
    t.fk_badge.configuration.overflowSuffix = "+"
    t.fk_badge.showCount(250)
    let cap = UILabel()
    cap.font = .preferredFont(forTextStyle: .caption1)
    cap.textColor = .secondaryLabel
    cap.text = "maxDisplayCount=199 → 199+"
    cap.numberOfLines = 0
    customBox.addArrangedSubview(t)
    customBox.addArrangedSubview(cap)

    let replayChip = FKBadgeExampleSupport.makeChipTarget()
    replayChip.fk_badge.showCount(88)
    replayChip.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -3, vertical: 3))
    let replayRow = UIStackView()
    replayRow.axis = .horizontal
    replayRow.spacing = 8
    replayRow.distribution = .fillEqually
    replayRow.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Replay Pop") {
      replayChip.fk_badge.showCount(88, animation: .pop(fromScale: 0.2, overshootScale: 1.1, duration: 0.25))
    })
    replayRow.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Replay Pulse") {
      replayChip.fk_badge.showCount(88, animation: .pulse(scale: 1.15, duration: 0.5))
    })

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Replay entrance animations on the same badge."

    box.addArrangedSubview(g1)
    box.addArrangedSubview(g2)
    box.addArrangedSubview(customBox)
    box.addArrangedSubview(FKBadgeExampleSupport.leadingAlignedChipContainer(replayChip))
    box.addArrangedSubview(replayRow)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }

  private func buildTextSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Text: New / Hot / VIP / Pick")
    let g = UIStackView()
    g.axis = .horizontal
    g.spacing = 8
    g.alignment = .center
    g.distribution = .equalSpacing
    ["New", "Hot", "VIP", "Pick"].forEach { text in
      g.addArrangedSubview(FKBadgeExampleSupport.textDemoChip(text))
    }
    box.addArrangedSubview(g)
    contentStack.addArrangedSubview(box)
  }
}
