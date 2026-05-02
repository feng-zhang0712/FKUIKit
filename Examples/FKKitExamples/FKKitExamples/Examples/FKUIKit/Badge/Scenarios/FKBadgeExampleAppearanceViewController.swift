import UIKit
import FKUIKit

final class FKBadgeExampleAppearanceViewController: FKBadgeExampleScrollViewController {

  private let styledHost = UIView()
  private let visibilityHost = UIView()
  private let visibilityBadgeTarget = UIView()

  private lazy var visibilitySegment: UISegmentedControl = {
    let s = UISegmentedControl(items: ["Auto", "Forced hidden", "Forced visible"])
    s.selectedSegmentIndex = 0
    s.addTarget(self, action: #selector(visibilityPolicyChanged), for: .valueChanged)
    return s
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    installScrollRootChrome()
    buildStyledSection()
    buildVisibilitySection()
    buildAnimationSection()
    buildStringParseSection()
  }

  private func buildStyledSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Border, fill, custom corner radius")

    styledHost.backgroundColor = .secondarySystemFill
    styledHost.layer.cornerRadius = 12
    styledHost.translatesAutoresizingMaskIntoConstraints = false

    let inner = UIView()
    inner.backgroundColor = .clear
    inner.translatesAutoresizingMaskIntoConstraints = false
    styledHost.addSubview(inner)

    NSLayoutConstraint.activate([
      styledHost.heightAnchor.constraint(equalToConstant: 72),
      inner.centerXAnchor.constraint(equalTo: styledHost.centerXAnchor),
      inner.centerYAnchor.constraint(equalTo: styledHost.centerYAnchor),
      inner.widthAnchor.constraint(equalToConstant: 160),
      inner.heightAnchor.constraint(equalToConstant: 44),
    ])

    var cfg = FKBadgeConfiguration()
    cfg.backgroundColor = UIColor.systemGreen
    cfg.titleColor = .white
    cfg.borderWidth = 2
    cfg.borderColor = UIColor.white.withAlphaComponent(0.9)
    cfg.horizontalPadding = 8
    cfg.verticalPadding = 4
    cfg.font = .systemFont(ofSize: 12, weight: .bold)
    cfg.textCornerRadius = 6
    inner.fk_badge.configuration = cfg
    inner.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -2, vertical: 2))
    inner.fk_badge.showText("Pick")

    box.addArrangedSubview(styledHost)
    contentStack.addArrangedSubview(box)
  }

  private func buildVisibilitySection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Visibility: 0 hides; forced visible shows “0”")

    visibilityHost.backgroundColor = .secondarySystemFill
    visibilityHost.layer.cornerRadius = 12
    visibilityHost.translatesAutoresizingMaskIntoConstraints = false

    visibilityBadgeTarget.backgroundColor = .systemPurple.withAlphaComponent(0.25)
    visibilityBadgeTarget.layer.cornerRadius = 8
    visibilityBadgeTarget.translatesAutoresizingMaskIntoConstraints = false
    visibilityHost.addSubview(visibilityBadgeTarget)

    NSLayoutConstraint.activate([
      visibilityHost.heightAnchor.constraint(equalToConstant: 88),
      visibilityBadgeTarget.centerXAnchor.constraint(equalTo: visibilityHost.centerXAnchor),
      visibilityBadgeTarget.centerYAnchor.constraint(equalTo: visibilityHost.centerYAnchor),
      visibilityBadgeTarget.widthAnchor.constraint(equalToConstant: 140),
      visibilityBadgeTarget.heightAnchor.constraint(equalToConstant: 48),
    ])

    visibilityBadgeTarget.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -4, vertical: 4))
    visibilityBadgeTarget.fk_badge.showCount(0)

    let g = UIStackView()
    g.axis = .horizontal
    g.spacing = 8
    g.distribution = .fillEqually
    g.addArrangedSubview(visibilitySegment)

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Set 0") { [weak self] in
      self?.visibilityBadgeTarget.fk_badge.showCount(0)
      self?.syncVisibilityPolicyToBadge()
    })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Set 12") { [weak self] in
      self?.visibilityBadgeTarget.fk_badge.showCount(12)
      self?.syncVisibilityPolicyToBadge()
    })

    box.addArrangedSubview(g)
    box.addArrangedSubview(visibilityHost)
    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)

    syncVisibilityPolicyToBadge()
  }

  private func buildAnimationSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Animations: pop / blink / pulse")

    let host = UIView()
    host.backgroundColor = .secondarySystemFill
    host.layer.cornerRadius = 12
    host.translatesAutoresizingMaskIntoConstraints = false
    let t = UIView()
    t.backgroundColor = .systemRed.withAlphaComponent(0.2)
    t.layer.cornerRadius = 8
    t.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(t)
    NSLayoutConstraint.activate([
      host.heightAnchor.constraint(equalToConstant: 80),
      t.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      t.centerYAnchor.constraint(equalTo: host.centerYAnchor),
      t.widthAnchor.constraint(equalToConstant: 100),
      t.heightAnchor.constraint(equalToConstant: 44),
    ])

    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Pop") {
      t.fk_badge.showCount(5, animation: .pop())
    })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Blink") {
      t.fk_badge.showCount(5, animation: .blink())
    })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Pulse") {
      t.fk_badge.showCount(5, animation: .pulse())
    })

    t.fk_badge.showCount(5, animation: .pop())

    box.addArrangedSubview(row)
    box.addArrangedSubview(host)
    contentStack.addArrangedSubview(box)
  }

  private func buildStringParseSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "setCount(parsing:): invalid hides")

    let t = FKBadgeExampleSupport.makeChipTarget()
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("\"42\"") { t.fk_badge.setCount(parsing: "42") })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Invalid") { t.fk_badge.setCount(parsing: "12a") })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Clear") { t.fk_badge.clear() })

    box.addArrangedSubview(row)
    box.addArrangedSubview(FKBadgeExampleSupport.leadingAlignedChipContainer(t))
    contentStack.addArrangedSubview(box)
  }

  @objc private func visibilityPolicyChanged() {
    syncVisibilityPolicyToBadge()
  }

  private func syncVisibilityPolicyToBadge() {
    let policy: FKBadgeVisibilityPolicy
    switch visibilitySegment.selectedSegmentIndex {
    case 1: policy = .forcedHidden
    case 2: policy = .forcedVisible
    default: policy = .automatic
    }
    visibilityBadgeTarget.fk_badge.visibilityPolicy = policy
  }
}
