import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Shared UI Helpers

private enum FKToastDemoUI {
  static func makeScrollContent(in viewController: UIViewController) -> (UIScrollView, UIStackView) {
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 14
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
    return (scroll, stack)
  }

  static func section(_ title: String, _ body: UIView) -> UIView {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8

    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .headline)
    wrap.addArrangedSubview(label)
    wrap.addArrangedSubview(body)
    return wrap
  }

  static func row(_ views: [UIView]) -> UIStackView {
    let row = UIStackView(arrangedSubviews: views)
    row.axis = .horizontal
    row.spacing = 8
    row.distribution = .fillEqually
    return row
  }

  static func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 10
    button.heightAnchor.constraint(equalToConstant: 40).isActive = true
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
  }
}

fileprivate class FKToastDemoBaseViewController: UIViewController {
  var contentStack: UIStackView!

  init() { super.init(nibName: nil, bundle: nil) }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    (_, contentStack) = FKToastDemoUI.makeScrollContent(in: self)
  }
}

// MARK: - Hub

final class FKToastExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: "Basics", subtitle: "Five preset styles", make: { FKToastBasicsViewController() }),
    Row(title: "Positions", subtitle: "Top / center / bottom placement", make: { FKToastPositionViewController() }),
    Row(title: "Animations", subtitle: "Fade and slide transitions", make: { FKToastAnimationViewController() }),
    Row(title: "Interaction", subtitle: "Tap close / swipe close / manual clear", make: { FKToastInteractionViewController() }),
    Row(title: "Duration", subtitle: "Custom duration and persistent message", make: { FKToastDurationViewController() }),
    Row(title: "Custom Style", subtitle: "Color, font, corner, shadow, icon", make: { FKToastCustomStyleViewController() }),
    Row(title: "Custom View", subtitle: "UIView and SwiftUI content", make: { FKToastCustomViewDemoViewController() }),
    Row(title: "Queue", subtitle: "Sequential queue behavior under bursts", make: { FKToastQueueViewController() }),
    Row(title: "Global Config", subtitle: "Apply and reset global defaults", make: { FKToastGlobalConfigViewController() }),
    Row(title: "Dark Mode", subtitle: "Light/Dark adaptation preview", make: { FKToastAppearanceViewController() }),
    Row(title: "SwiftUI Demo", subtitle: "Standalone SwiftUI usage page", make: { FKToastSwiftUIHostViewController() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKToast"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}

// MARK: - Scenarios

fileprivate final class FKToastBasicsViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics"

    let col = UIStackView()
    col.axis = .vertical
    col.spacing = 8
    col.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Normal") { FKToast.show("Plain message", style: .normal) },
      FKToastDemoUI.button("Success") { FKToast.show("Saved successfully", style: .success) },
    ]))
    col.addArrangedSubview(FKToastDemoUI.row([
      FKToastDemoUI.button("Error") { FKToast.show("Request failed", style: .error) },
      FKToastDemoUI.button("Warning") { FKToast.show("Storage almost full", style: .warning) },
    ]))
    col.addArrangedSubview(FKToastDemoUI.button("Info") { FKToast.show("New update available", style: .info) })
    contentStack.addArrangedSubview(FKToastDemoUI.section("Preset Styles", col))
  }
}

fileprivate final class FKToastPositionViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Positions"
    let col = UIStackView()
    col.axis = .vertical
    col.spacing = 8
    col.addArrangedSubview(FKToastDemoUI.button("Top") {
      FKToast.show("Top positioned toast", configuration: .init(style: .info, position: .top))
    })
    col.addArrangedSubview(FKToastDemoUI.button("Center") {
      FKToast.show("Center positioned toast", configuration: .init(style: .normal, position: .center))
    })
    col.addArrangedSubview(FKToastDemoUI.button("Bottom Snackbar") {
      FKToast.show("Bottom snackbar", configuration: .init(kind: .snackbar, style: .success, position: .bottom))
    })
    contentStack.addArrangedSubview(FKToastDemoUI.section("Show Positions", col))
  }
}

fileprivate final class FKToastAnimationViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Animations"
    contentStack.addArrangedSubview(FKToastDemoUI.section("Animation Options", FKToastDemoUI.row([
      FKToastDemoUI.button("Fade") {
        var c = FKToastConfiguration(style: .info, position: .top)
        c.animationStyle = .fade
        FKToast.show("Fade in/out", configuration: c)
      },
      FKToastDemoUI.button("Slide") {
        var c = FKToastConfiguration(style: .success, position: .bottom)
        c.animationStyle = .slide
        FKToast.show("Slide animation", configuration: c)
      },
    ])))
  }
}

fileprivate final class FKToastInteractionViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Interaction"
    let col = UIStackView()
    col.axis = .vertical
    col.spacing = 8
    col.addArrangedSubview(FKToastDemoUI.button("Show (tap/swipe enabled)") {
      var c = FKToastConfiguration(kind: .snackbar, style: .normal, duration: 5)
      c.tapToDismiss = true
      c.swipeToDismiss = true
      FKToast.show("Tap or swipe this snackbar", configuration: c)
    })
    col.addArrangedSubview(FKToastDemoUI.button("Manual clearAll()") {
      FKToast.clearAll(animated: true)
    })
    contentStack.addArrangedSubview(FKToastDemoUI.section("Interaction", col))
  }
}

fileprivate final class FKToastDurationViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Duration"
    contentStack.addArrangedSubview(FKToastDemoUI.section("Duration", FKToastDemoUI.row([
      FKToastDemoUI.button("0.8s") {
        FKToast.show("Short duration", configuration: .init(style: .info, duration: 0.8))
      },
      FKToastDemoUI.button("Persistent") {
        var c = FKToastConfiguration(kind: .snackbar, style: .warning, duration: 0)
        c.action = .init(title: "CLOSE")
        FKToast.show("Persistent until interaction", configuration: c) {
          FKToast.clearAll(animated: true)
        }
      },
    ])))
  }
}

fileprivate final class FKToastCustomStyleViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Style"
    let show = FKToastDemoUI.button("Show custom styled toast") {
      var c = FKToastConfiguration(kind: .snackbar, style: .normal, duration: 3)
      c.backgroundColor = .black
      c.textColor = .systemMint
      c.iconTintColor = .systemMint
      c.cornerRadius = 18
      c.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
      c.showsShadow = true
      c.shadowOpacity = 0.34
      c.shadowRadius = 18
      c.animationStyle = .slide
      FKToast.show(
        "Custom color, corner, font, shadow and icon",
        icon: UIImage(systemName: "star.fill"),
        configuration: c
      )
    }
    contentStack.addArrangedSubview(FKToastDemoUI.section("Custom Configuration", show))
  }
}

fileprivate final class FKToastCustomViewDemoViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom View"
    let col = UIStackView()
    col.axis = .vertical
    col.spacing = 8

    col.addArrangedSubview(FKToastDemoUI.button("UIKit custom UIView") {
      let h = UIStackView()
      h.axis = .horizontal
      h.spacing = 8
      let dot = UIView()
      dot.backgroundColor = .systemGreen
      dot.layer.cornerRadius = 5
      dot.translatesAutoresizingMaskIntoConstraints = false
      dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
      dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
      let text = UILabel()
      text.text = "Realtime connection recovered"
      text.textColor = .white
      text.font = .preferredFont(forTextStyle: .subheadline)
      h.addArrangedSubview(dot)
      h.addArrangedSubview(text)
      FKToast.show(customView: h, configuration: .init(kind: .toast, style: .normal))
    })

    col.addArrangedSubview(FKToastDemoUI.button("SwiftUI custom View") {
      #if canImport(SwiftUI)
      FKToast.show(
        swiftUIView: FKToastSwiftUITagView(),
        configuration: .init(kind: .toast, style: .info)
      )
      #endif
    })
    contentStack.addArrangedSubview(FKToastDemoUI.section("Custom View", col))
  }
}

fileprivate final class FKToastQueueViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Queue"
    let button = FKToastDemoUI.button("Push 5 messages quickly") {
      ["Step 1", "Step 2", "Step 3", "Step 4", "Done"].enumerated().forEach { index, text in
        let style: FKToastStyle = index == 4 ? .success : .info
        FKToast.show(text, style: style, kind: .snackbar)
      }
    }
    contentStack.addArrangedSubview(FKToastDemoUI.section("Queue Demonstration", button))
  }
}

fileprivate final class FKToastGlobalConfigViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global Config"
    let col = UIStackView()
    col.axis = .vertical
    col.spacing = 8
    col.addArrangedSubview(FKToastDemoUI.button("Apply global defaults") {
      var global = FKToastConfiguration(kind: .snackbar, style: .info)
      global.position = .top
      global.duration = 2.8
      global.animationStyle = .fade
      global.cornerRadius = 12
      FKToast.defaultConfiguration = global
      FKToast.show("Global defaults applied", configuration: global)
    })
    col.addArrangedSubview(FKToastDemoUI.button("Reset global defaults") {
      FKToast.defaultConfiguration = FKToastConfiguration()
      FKToast.show("Global defaults reset", style: .normal, kind: .toast)
    })
    contentStack.addArrangedSubview(FKToastDemoUI.section("Global Configuration", col))
  }
}

fileprivate final class FKToastAppearanceViewController: FKToastDemoBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark Mode"
    let seg = UISegmentedControl(items: ["System", "Light", "Dark"])
    seg.selectedSegmentIndex = 0
    seg.addAction(UIAction { [weak self] action in
      guard let self, let sender = action.sender as? UISegmentedControl else { return }
      switch sender.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)
    seg.heightAnchor.constraint(equalToConstant: 36).isActive = true

    let button = FKToastDemoUI.button("Preview adaptive style") {
      FKToast.show("Adaptive color in current appearance", style: .normal, kind: .toast)
    }
    let stack = UIStackView(arrangedSubviews: [seg, button])
    stack.axis = .vertical
    stack.spacing = 8
    contentStack.addArrangedSubview(FKToastDemoUI.section("Dark / Light Appearance", stack))
  }
}

// MARK: - SwiftUI Standalone Demo

final class FKToastSwiftUIHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Demo"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKToastSwiftUIScreen())
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
    label.text = "SwiftUI is unavailable in this build."
    label.textAlignment = .center
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
private struct FKToastSwiftUITagView: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("SwiftUI custom toast content")
        .font(.subheadline)
    }
    .foregroundStyle(.white)
  }
}

private struct FKToastSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        Text("SwiftUI FKToast Demo")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        Button("Show success snackbar") {
          FKToast.show("Saved from SwiftUI", style: .success, kind: .snackbar)
        }
        .buttonStyle(.borderedProminent)

        Button("Show top warning toast") {
          FKToast.show("Upload paused", configuration: .init(kind: .toast, style: .warning, position: .top))
        }
        .buttonStyle(.bordered)

        Button("Show custom SwiftUI content") {
          FKToast.show(swiftUIView: FKToastSwiftUITagView(), configuration: .init(style: .info))
        }
        .buttonStyle(.bordered)

        Button("Queue 3 messages") {
          FKToast.show("Queue 1", style: .info, kind: .snackbar)
          FKToast.show("Queue 2", style: .info, kind: .snackbar)
          FKToast.show("Queue 3", style: .success, kind: .snackbar)
        }
        .buttonStyle(.bordered)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
