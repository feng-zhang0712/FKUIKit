import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Shared UI Helpers

private enum FKDividerDemoUI {
  // Shared scroll container so all examples stay accessible in portrait/landscape.
  static func makeScrollStack(in viewController: UIViewController) -> UIStackView {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)

    viewController.view.addSubview(scroll)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
      scroll.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
      scroll.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),

      stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
      stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
    ])
    return stack
  }

  static func card(title: String, description: String, content: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 10
    wrap.backgroundColor = .secondarySystemGroupedBackground
    wrap.layer.cornerRadius = 12
    wrap.isLayoutMarginsRelativeArrangement = true
    wrap.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)

    let t = UILabel()
    t.text = title
    t.font = .preferredFont(forTextStyle: .headline)
    let d = UILabel()
    d.text = description
    d.textColor = .secondaryLabel
    d.numberOfLines = 0
    d.font = .preferredFont(forTextStyle: .footnote)

    wrap.addArrangedSubview(t)
    wrap.addArrangedSubview(d)
    wrap.addArrangedSubview(content)
    return wrap
  }

  static func sampleBox(height: CGFloat = 56) -> UIView {
    let v = UIView()
    v.backgroundColor = .tertiarySystemFill
    v.layer.cornerRadius = 10
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    return v
  }
}

private class FKDividerDemoBaseViewController: UIViewController {
  var stack: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    stack = FKDividerDemoUI.makeScrollStack(in: self)
  }
}

// MARK: - Hub

final class FKDividerExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: "Horizontal Solid", subtitle: "Basic horizontal solid divider", make: { FKDividerHorizontalBasicVC() }),
    Row(title: "Vertical Solid", subtitle: "Basic vertical solid divider", make: { FKDividerVerticalBasicVC() }),
    Row(title: "1px Auto Scale", subtitle: "1 physical-pixel auto scaling", make: { FKDividerPixelPerfectVC() }),
    Row(title: "Indent", subtitle: "Divider with left and right insets", make: { FKDividerIndentVC() }),
    Row(title: "Thickness", subtitle: "Different divider thickness values", make: { FKDividerThicknessVC() }),
    Row(title: "Color", subtitle: "Different divider colors", make: { FKDividerColorVC() }),
    Row(title: "Dashed", subtitle: "Basic dashed divider", make: { FKDividerDashedVC() }),
    Row(title: "Dash Pattern", subtitle: "Different dash patterns", make: { FKDividerDashPatternVC() }),
    Row(title: "Gradient", subtitle: "Gradient divider", make: { FKDividerGradientVC() }),
    Row(title: "Auto Pin Top", subtitle: "Auto pin to top edge", make: { FKDividerPinTopVC() }),
    Row(title: "Auto Pin Bottom", subtitle: "Auto pin to bottom edge", make: { FKDividerPinBottomVC() }),
    Row(title: "Auto Pin Left/Right", subtitle: "Auto pin to left and right edges", make: { FKDividerPinSidesVC() }),
    Row(title: "Global Config", subtitle: "Update global default configuration", make: { FKDividerGlobalConfigVC() }),
    Row(title: "IB / Storyboard", subtitle: "XIB/Storyboard setup preview", make: { FKDividerIBDemoVC() }),
    Row(title: "SwiftUI", subtitle: "SwiftUI-specific divider demo", make: { FKDividerSwiftUIHostVC() }),
    Row(title: "Dark Mode", subtitle: "Dark mode adaptation demo", make: { FKDividerDarkModeVC() }),
    Row(title: "Rotation", subtitle: "Screen rotation adaptation demo", make: { FKDividerRotationVC() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKDivider"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}

// MARK: - Scenario Pages

fileprivate final class FKDividerHorizontalBasicVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Horizontal Solid"
    // Basic horizontal solid divider: common list separator style.
    let box = FKDividerDemoUI.sampleBox()
    let divider = FKDivider(configuration: .init(direction: .horizontal, lineStyle: .solid))
    divider.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(divider)
    NSLayoutConstraint.activate([
      divider.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      divider.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      divider.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Horizontal Solid", description: "Basic horizontal divider.", content: box))
  }
}

fileprivate final class FKDividerVerticalBasicVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Vertical Solid"
    // Basic vertical solid divider: useful for left/right region splitting.
    let box = FKDividerDemoUI.sampleBox(height: 80)
    let divider = FKDivider(configuration: .init(direction: .vertical))
    divider.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(divider)
    NSLayoutConstraint.activate([
      divider.topAnchor.constraint(equalTo: box.topAnchor),
      divider.bottomAnchor.constraint(equalTo: box.bottomAnchor),
      divider.centerXAnchor.constraint(equalTo: box.centerXAnchor),
      divider.widthAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Vertical Solid", description: "Basic vertical divider.", content: box))
  }
}

fileprivate final class FKDividerPixelPerfectVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "1px Auto Scale"
    // 1 physical pixel adaptation: keep lines crisp on different screen scales.
    var c = FKDividerConfiguration()
    c.isPixelPerfect = true
    c.thickness = 3
    let box = FKDividerDemoUI.sampleBox()
    let divider = FKDivider(configuration: c)
    divider.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(divider)
    NSLayoutConstraint.activate([
      divider.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      divider.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      divider.heightAnchor.constraint(equalToConstant: 3),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "1px Auto Scale", description: "Enabled `isPixelPerfect = true` to force physical-pixel rendering.", content: box))
  }
}

fileprivate final class FKDividerIndentVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indent"
    // Indent effect: use contentInsets to shorten the effective stroke area.
    var c = FKDividerConfiguration()
    c.contentInsets = .init(top: 0, left: 28, bottom: 0, right: 28)
    let box = FKDividerDemoUI.sampleBox()
    let divider = FKDivider(configuration: c)
    divider.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(divider)
    NSLayoutConstraint.activate([
      divider.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      divider.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      divider.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      divider.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Indent", description: "Use left/right content insets.", content: box))
  }
}

fileprivate final class FKDividerThicknessVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Thickness"
    // Different line widths: render by logical points after disabling pixel-perfect mode.
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10
    [1.0, 2.0, 4.0].forEach { w in
      let row = FKDividerDemoUI.sampleBox(height: 36)
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
      column.addArrangedSubview(row)
    }
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Thickness", description: "1pt / 2pt / 4pt examples.", content: column))
  }
}

fileprivate final class FKDividerColorVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Color"
    // Different colors: demonstrate theme and semantic colors.
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10
    [UIColor.systemRed, .systemBlue, .systemGreen].forEach { color in
      let row = FKDividerDemoUI.sampleBox(height: 32)
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
      column.addArrangedSubview(row)
    }
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Color", description: "Red / Blue / Green divider colors.", content: column))
  }
}

fileprivate final class FKDividerDashedVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dashed"
    // Basic dashed divider: only switching lineStyle is required.
    var c = FKDividerConfiguration()
    c.lineStyle = .dashed
    let box = FKDividerDemoUI.sampleBox()
    let d = FKDivider(configuration: c)
    d.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(d)
    NSLayoutConstraint.activate([
      d.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      d.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      d.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Dashed Divider", description: "Basic dashed line style.", content: box))
  }
}

fileprivate final class FKDividerDashPatternVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dash Pattern"
    // Different dash patterns: control stroke segment and gap lengths.
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10
    [[2, 2], [6, 3], [10, 4]].forEach { pattern in
      let row = FKDividerDemoUI.sampleBox(height: 32)
      var c = FKDividerConfiguration()
      c.lineStyle = .dashed
      c.dashPattern = pattern.map { NSNumber(value: $0) }
      let d = FKDivider(configuration: c)
      d.translatesAutoresizingMaskIntoConstraints = false
      row.addSubview(d)
      NSLayoutConstraint.activate([
        d.leadingAnchor.constraint(equalTo: row.leadingAnchor),
        d.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        d.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        d.heightAnchor.constraint(equalToConstant: 1),
      ])
      column.addArrangedSubview(row)
    }
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Dash Pattern", description: "Pattern: [2,2], [6,3], [10,4].", content: column))
  }
}

fileprivate final class FKDividerGradientVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Gradient"
    // Gradient divider: supports configurable colors and direction.
    let column = UIStackView()
    column.axis = .vertical
    column.spacing = 10

    let h = FKDividerDemoUI.sampleBox(height: 36)
    var hc = FKDividerConfiguration()
    hc.showsGradient = true
    hc.gradientDirection = .horizontal
    hc.gradientStartColor = .systemPink
    hc.gradientEndColor = .systemPurple
    let hd = FKDivider(configuration: hc)
    hd.translatesAutoresizingMaskIntoConstraints = false
    h.addSubview(hd)
    NSLayoutConstraint.activate([
      hd.leadingAnchor.constraint(equalTo: h.leadingAnchor),
      hd.trailingAnchor.constraint(equalTo: h.trailingAnchor),
      hd.centerYAnchor.constraint(equalTo: h.centerYAnchor),
      hd.heightAnchor.constraint(equalToConstant: 1),
    ])
    column.addArrangedSubview(h)

    let v = FKDividerDemoUI.sampleBox(height: 88)
    var vc = FKDividerConfiguration(direction: .vertical)
    vc.showsGradient = true
    vc.gradientDirection = .vertical
    vc.gradientStartColor = .systemBlue
    vc.gradientEndColor = .systemTeal
    let vd = FKDivider(configuration: vc)
    vd.translatesAutoresizingMaskIntoConstraints = false
    v.addSubview(vd)
    NSLayoutConstraint.activate([
      vd.topAnchor.constraint(equalTo: v.topAnchor),
      vd.bottomAnchor.constraint(equalTo: v.bottomAnchor),
      vd.centerXAnchor.constraint(equalTo: v.centerXAnchor),
      vd.widthAnchor.constraint(equalToConstant: 1),
    ])
    column.addArrangedSubview(v)
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Gradient Divider", description: "Horizontal and vertical gradient divider examples.", content: column))
  }
}

fileprivate final class FKDividerPinTopVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Auto Pin Top"
    // Auto pin top: no manual constraints needed, call convenience extension directly.
    let box = FKDividerDemoUI.sampleBox(height: 64)
    box.fk_addDivider(at: .top, margin: 16)
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Pin Top", description: "Use `fk_addDivider(at: .top)`.", content: box))
  }
}

fileprivate final class FKDividerPinBottomVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Auto Pin Bottom"
    // Auto pin bottom: often used for card bottoms or list tails.
    let box = FKDividerDemoUI.sampleBox(height: 64)
    box.fk_addDivider(at: .bottom, margin: 16)
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Pin Bottom", description: "Use `fk_addDivider(at: .bottom)`.", content: box))
  }
}

fileprivate final class FKDividerPinSidesVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Auto Pin Left/Right"
    // Auto pin left/right: quickly split container boundaries.
    let box = FKDividerDemoUI.sampleBox(height: 84)
    box.fk_addDivider(at: .left, margin: 12)
    box.fk_addDivider(at: .right, margin: 12)
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Pin Left/Right", description: "Use `fk_addDivider(at: .left/.right)`.", content: box))
  }
}

fileprivate final class FKDividerGlobalConfigVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global Config"
    // Global defaults: unify project style while allowing per-instance overrides.
    let apply = UIButton(type: .system)
    apply.setTitle("Apply Global Default", for: .normal)
    apply.addAction(UIAction { _ in
      var g = FKDividerConfiguration()
      g.color = .systemOrange
      g.isPixelPerfect = false
      g.thickness = 2
      FKDividerManager.shared.defaultConfiguration = g
    }, for: .touchUpInside)

    let preview = UIButton(type: .system)
    preview.setTitle("Create Divider From Global", for: .normal)
    preview.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let box = FKDividerDemoUI.sampleBox(height: 40)
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

    let col = UIStackView(arrangedSubviews: [apply, preview])
    col.axis = .vertical
    col.spacing = 8
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Global Configuration", description: "Update `FKDividerManager.shared.defaultConfiguration`.", content: col))
  }
}

fileprivate final class FKDividerIBDemoVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "IB / Storyboard"
    // XIB/Storyboard guidance:
    // 1) Place a UIView in IB and set its class to FKDivider.
    // 2) Configure visual properties via ibDirection / ibLineStyle / ibDashLength, etc.
    // 3) This page simulates IBInspectable setup in code for copy-ready usage.
    let box = FKDividerDemoUI.sampleBox(height: 64)
    let d = FKDivider()
    d.ibDirection = 0
    d.ibLineStyle = 1
    d.ibDashLength = 8
    d.ibDashGap = 3
    d.ibInsetLeft = 20
    d.ibInsetRight = 20
    d.ibShowsGradient = true
    d.ibGradientStartColor = .systemIndigo
    d.ibGradientEndColor = .systemCyan
    d.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(d)
    NSLayoutConstraint.activate([
      d.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      d.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      d.heightAnchor.constraint(equalToConstant: 1),
    ])
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Interface Builder Simulation", description: "Programmatic simulation of IBInspectable properties.", content: box))
  }
}

fileprivate final class FKDividerDarkModeVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark Mode"
    // Dark mode adaptation: dynamic colors (for example .separator) follow appearance automatically.
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

    let box = FKDividerDemoUI.sampleBox()
    let d = FKDivider(configuration: .init(color: .separator))
    d.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(d)
    NSLayoutConstraint.activate([
      d.leadingAnchor.constraint(equalTo: box.leadingAnchor),
      d.trailingAnchor.constraint(equalTo: box.trailingAnchor),
      d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      d.heightAnchor.constraint(equalToConstant: 1),
    ])

    let col = UIStackView(arrangedSubviews: [seg, box])
    col.axis = .vertical
    col.spacing = 8
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Dark Mode Adaptation", description: "Switch appearance and observe dynamic divider color.", content: col))
  }
}

fileprivate final class FKDividerRotationVC: FKDividerDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rotation"
    // Rotation adaptation: Auto Layout keeps divider geometry updated across orientation changes.
    let hint = UILabel()
    hint.text = "Rotate the device/simulator to verify divider relayout."
    hint.textColor = .secondaryLabel
    hint.numberOfLines = 0

    let box = FKDividerDemoUI.sampleBox(height: 120)
    let d = FKDivider(configuration: .init(direction: .horizontal, showsGradient: true, gradientStartColor: .systemPink, gradientEndColor: .systemPurple))
    d.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(d)
    NSLayoutConstraint.activate([
      d.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
      d.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
      d.centerYAnchor.constraint(equalTo: box.centerYAnchor),
      d.heightAnchor.constraint(equalToConstant: 1),
    ])
    let col = UIStackView(arrangedSubviews: [hint, box])
    col.axis = .vertical
    col.spacing = 8
    stack.addArrangedSubview(FKDividerDemoUI.card(title: "Rotation Adaptation", description: "Auto Layout keeps divider aligned after rotation.", content: col))
  }
}

// MARK: - SwiftUI Demo

final class FKDividerSwiftUIHostVC: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKDividerSwiftUIScreen())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.backgroundColor = .clear
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #else
    let label = UILabel()
    label.text = "SwiftUI unavailable."
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKDividerSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("SwiftUI Divider Demo")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        FKDividerView(
          configuration: .init(
            direction: .horizontal,
            lineStyle: .solid,
            color: .separator
          )
        )
        .frame(height: 1)

        FKDividerView(
          configuration: .init(
            direction: .horizontal,
            lineStyle: .dashed,
            dashPattern: [6, 3],
            showsGradient: true,
            gradientStartColor: .systemPink,
            gradientEndColor: .systemPurple
          )
        )
        .frame(height: 1)

        HStack {
          Text("Left")
          FKDividerView(configuration: .init(direction: .vertical, color: .systemBlue))
            .frame(width: 1, height: 36)
          Text("Right")
        }
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
