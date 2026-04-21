//
//  FKBadgeExamplesHubViewController.swift
//  FKKitExamples
//
//  FKBadge demos: hub, category screens, and shared layout helpers (single-file organization).
//

import UIKit
import FKUIKit

// MARK: - Support

/// Shared layout helpers for FKBadge example screens.
enum FKBadgeExampleSupport {

  static func makeRootScrollStack() -> (UIScrollView, UIStackView) {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    let contentStack = UIStackView()
    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.spacing = 20
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    return (scrollView, contentStack)
  }

  static func pinScrollView(
    _ scrollView: UIScrollView,
    contentStack: UIStackView,
    in view: UIView
  ) {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Pin the stack to the scroll view's content layout, then lock its width to the scroll view.
      // This keeps Auto Layout deterministic and allows vertical scrolling based on content height.
      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  static func addGlobalBadgeBarButtons(to vc: UIViewController) {
    vc.navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Hide all",
        image: nil,
        primaryAction: UIAction { _ in FKBadge.hideAllBadges(animated: true) },
        menu: nil
      ),
      UIBarButtonItem(
        title: "Restore all",
        image: nil,
        primaryAction: UIAction { _ in FKBadge.restoreAllBadges(animated: true) },
        menu: nil
      ),
    ]
  }

  static func sectionContainer(title: String) -> UIStackView {
    let outer = UIStackView()
    outer.axis = .vertical
    outer.alignment = .fill
    outer.spacing = 8
    let h = UILabel()
    h.font = .preferredFont(forTextStyle: .subheadline)
    h.textColor = .secondaryLabel
    h.text = title
    outer.addArrangedSubview(h)
    return outer
  }

  /// Vertical stacks with `.fill` stretch subviews to full width; wrap a fixed-width chip so it is not stretched horizontally.
  static func leadingAlignedChipContainer(_ chip: UIView) -> UIView {
    let wrap = UIView()
    wrap.translatesAutoresizingMaskIntoConstraints = false
    wrap.addSubview(chip)
    NSLayoutConstraint.activate([
      // Only constrain the leading edge; the chip keeps its intrinsic/fixed width.
      chip.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      chip.topAnchor.constraint(equalTo: wrap.topAnchor),
      chip.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
    ])
    return wrap
  }

  static func makeChipTarget() -> UIView {
    let v = UIView()
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 8
    v.translatesAutoresizingMaskIntoConstraints = false
    v.widthAnchor.constraint(equalToConstant: 56).isActive = true
    v.heightAnchor.constraint(equalToConstant: 56).isActive = true
    return v
  }

  static func staticNumberChip(_ n: Int) -> UIView {
    let v = makeChipTarget()
    v.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -3, vertical: 3))
    v.fk_badge.showCount(n)
    return v
  }

  static func textDemoChip(_ text: String) -> UIView {
    let wrap = UIView()
    wrap.backgroundColor = .secondarySystemFill
    wrap.layer.cornerRadius = 8
    wrap.translatesAutoresizingMaskIntoConstraints = false
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 13, weight: .medium)
    l.textAlignment = .center
    l.translatesAutoresizingMaskIntoConstraints = false
    wrap.addSubview(l)
    NSLayoutConstraint.activate([
      wrap.heightAnchor.constraint(equalToConstant: 44),
      l.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
      l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 8),
      l.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -8),
    ])
    wrap.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -2, vertical: 2))
    wrap.fk_badge.showText(text)
    return wrap
  }

  static func styleCornerHost(_ v: UIView) {
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 8
    v.translatesAutoresizingMaskIntoConstraints = false
  }

  static func applyAnchor(_ a: FKBadgeAnchor, to target: UIView) {
    let inset = CGFloat(4)
    switch a {
    case .topLeading:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: inset, vertical: inset))
    case .topTrailing:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: -inset, vertical: inset))
    case .bottomLeading:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: inset, vertical: -inset))
    case .bottomTrailing:
      target.fk_badge.setAnchor(a, offset: UIOffset(horizontal: -inset, vertical: -inset))
    case .center:
      target.fk_badge.setAnchor(a, offset: .zero)
    }
    target.fk_badge.showCount(7)
  }

  static func makeActionButton(_ title: String, handler: @escaping () -> Void) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.backgroundColor = .secondarySystemFill
    b.layer.cornerRadius = 8
    b.addAction(UIAction { _ in handler() }, for: .touchUpInside)
    b.heightAnchor.constraint(equalToConstant: 36).isActive = true
    return b
  }
}

// MARK: - Hub

/// Entry list: each row opens a focused FKBadge demo screen.
final class FKBadgeExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: "Basics & numbers",
      subtitle: "Interface style, dot, numeric counts, text badges",
      controllerType: FKBadgeExampleBasicsViewController.self
    ),
    Row(
      title: "Anchors & layout",
      subtitle: "Corner anchors, four-corner grid, offset slider",
      controllerType: FKBadgeExampleAnchorsViewController.self
    ),
    Row(
      title: "Appearance & behavior",
      subtitle: "Styling, visibility policy, animations, string parsing",
      controllerType: FKBadgeExampleAppearanceViewController.self
    ),
    Row(
      title: "System integration",
      subtitle: "UITabBarItem, bar-button pattern, RTL",
      controllerType: FKBadgeExampleIntegrationViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBadge"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
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
    let row = rows[indexPath.row]
    let vc = row.controllerType.init(nibName: nil, bundle: nil)
    vc.title = row.title
    navigationController?.pushViewController(vc, animated: true)
  }
}

// MARK: - Basics & numbers

final class FKBadgeExampleBasicsViewController: UIViewController {

  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKBadgeExampleSupport.addGlobalBadgeBarButtons(to: self)
    FKBadgeExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)

    let hint = UILabel()
    hint.font = .preferredFont(forTextStyle: .footnote)
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0
    hint.text = "The badge is added as a sibling in the superview so the target’s clips and hit-testing stay unchanged."
    hint.translatesAutoresizingMaskIntoConstraints = false
    contentStack.addArrangedSubview(hint)

    buildInterfaceStyleSection()
    buildBasicsSection()
    buildNumericSection()
    buildTextSection()
  }

  private func buildInterfaceStyleSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Interface style: light / dark (dynamic colors follow when unspecified)")
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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Basics: dot only")
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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Numeric: 1–99, 99+, custom cap (static)")

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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Text badges: New / Hot / VIP / Pick")
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

// MARK: - Anchors & layout

final class FKBadgeExampleAnchorsViewController: UIViewController {

  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  private let anchorDemoHost = UIView()
  private let anchorDemoTarget = UIView()

  private let cornerTL = UIView()
  private let cornerTR = UIView()
  private let cornerBL = UIView()
  private let cornerBR = UIView()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKBadgeExampleSupport.addGlobalBadgeBarButtons(to: self)
    FKBadgeExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)

    buildAnchorInteractiveSection()
    buildFourCornersSection()
    buildOffsetSection()
  }

  private func buildAnchorInteractiveSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Anchors: four corners + center + inset (single target)")

    anchorDemoHost.backgroundColor = .secondarySystemFill
    anchorDemoHost.layer.cornerRadius = 12
    anchorDemoHost.translatesAutoresizingMaskIntoConstraints = false

    anchorDemoTarget.backgroundColor = .systemBlue.withAlphaComponent(0.25)
    anchorDemoTarget.layer.cornerRadius = 8
    anchorDemoTarget.translatesAutoresizingMaskIntoConstraints = false
    anchorDemoHost.addSubview(anchorDemoTarget)

    let seg = UISegmentedControl(items: [
      "TR", "TL", "BR", "BL", "C",
    ])
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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Four corners at once (relative constraints)")

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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Offset: slider to overlap the corner")

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
    cap.text = "Slider drives horizontal offset; vertical follows at 0.5× (demo)."

    box.addArrangedSubview(slider)
    box.addArrangedSubview(host)
    box.addArrangedSubview(cap)
    contentStack.addArrangedSubview(box)
  }
}

// MARK: - Appearance & behavior

final class FKBadgeExampleAppearanceViewController: UIViewController {

  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  private let styledHost = UIView()

  private let visibilityHost = UIView()
  private let visibilityBadgeTarget = UIView()

  private lazy var visibilitySegment: UISegmentedControl = {
    let s = UISegmentedControl(items: ["Auto", "Forced hidden", "Forced visible"])
    s.selectedSegmentIndex = 0
    s.addTarget(self, action: #selector(visibilityPolicyChanged), for: .valueChanged)
    return s
  }()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKBadgeExampleSupport.addGlobalBadgeBarButtons(to: self)
    FKBadgeExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)

    buildStyledSection()
    buildVisibilitySection()
    buildAnimationSection()
    buildStringParseSection()
  }

  private func buildStyledSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "Appearance: border, fill, custom corner radius (text)")

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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Visibility: count 0 hides; forced visible can show “0”")

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
    let box = FKBadgeExampleSupport.sectionContainer(title: "Count string parsing: invalid input hides the badge")

    let t = FKBadgeExampleSupport.makeChipTarget()
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("\"42\"") { t.fk_badge.showCountString("42") })
    row.addArrangedSubview(FKBadgeExampleSupport.makeActionButton("Invalid") { t.fk_badge.showCountString("12a") })
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

// MARK: - System integration

final class FKBadgeExampleIntegrationViewController: UIViewController {

  private let scrollView: UIScrollView
  private let contentStack: UIStackView

  private let demoTabBar = UITabBar()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    (scrollView, contentStack) = FKBadgeExampleSupport.makeRootScrollStack()
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    FKBadgeExampleSupport.addGlobalBadgeBarButtons(to: self)
    FKBadgeExampleSupport.pinScrollView(scrollView, contentStack: contentStack, in: view)

    buildTabBarSection()
    buildBarButtonItemSection()
    buildRTLSection()
  }

  private func buildTabBarSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "UITabBarItem: system badgeValue + same overflow rules")

    demoTabBar.items = [
      UITabBarItem(title: "Messages", image: UIImage(systemName: "bubble.left.fill"), tag: 0),
      UITabBarItem(title: "Profile", image: UIImage(systemName: "person.fill"), tag: 1),
    ]
    demoTabBar.selectedItem = demoTabBar.items?.first
    demoTabBar.items?.first?.fk_setBadgeCount(128, maxDisplay: 99)
    demoTabBar.translatesAutoresizingMaskIntoConstraints = false

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "fk_setBadgeCount(128) → 99+ (standalone UITabBar for demo only)."

    box.addArrangedSubview(demoTabBar)
    box.addArrangedSubview(note)

    NSLayoutConstraint.activate([
      demoTabBar.heightAnchor.constraint(equalToConstant: 49),
    ])
    contentStack.addArrangedSubview(box)
  }

  private func buildBarButtonItemSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "UIBarButtonItem: only customView can host a badge overlay")

    let barStrip = UIView()
    barStrip.backgroundColor = .secondarySystemBackground
    barStrip.layer.cornerRadius = 10
    barStrip.translatesAutoresizingMaskIntoConstraints = false

    let bell = UIButton(type: .system)
    bell.setImage(UIImage(systemName: "bell.fill"), for: .normal)
    bell.tintColor = .label
    bell.translatesAutoresizingMaskIntoConstraints = false
    bell.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: 2, vertical: -2))
    bell.fk_badge.showCount(5)

    barStrip.addSubview(bell)

    NSLayoutConstraint.activate([
      barStrip.heightAnchor.constraint(equalToConstant: 52),
      bell.trailingAnchor.constraint(equalTo: barStrip.trailingAnchor, constant: -16),
      bell.centerYAnchor.constraint(equalTo: barStrip.centerYAnchor),
      bell.widthAnchor.constraint(equalToConstant: 40),
      bell.heightAnchor.constraint(equalToConstant: 40),
    ])

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Fake nav bar trailing bell; same layout as `UIBarButtonItem(customView:)`."

    box.addArrangedSubview(barStrip)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }

  private func buildRTLSection() {
    let box = FKBadgeExampleSupport.sectionContainer(title: "RTL: container uses `semanticContentAttribute = .forceRightToLeft`")

    let wrap = UIView()
    wrap.semanticContentAttribute = .forceRightToLeft
    wrap.backgroundColor = .secondarySystemFill
    wrap.layer.cornerRadius = 12
    wrap.translatesAutoresizingMaskIntoConstraints = false

    let chip = FKBadgeExampleSupport.makeChipTarget()
    chip.fk_badge.showCount(9)
    chip.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -4, vertical: 4))
    wrap.addSubview(chip)

    NSLayoutConstraint.activate([
      wrap.heightAnchor.constraint(equalToConstant: 80),
      chip.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -20),
      chip.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
    ])

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .caption1)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text = "Badge uses trailing anchor; in RTL the layout mirrors so the badge moves with semantics."

    box.addArrangedSubview(wrap)
    box.addArrangedSubview(note)
    contentStack.addArrangedSubview(box)
  }
}
