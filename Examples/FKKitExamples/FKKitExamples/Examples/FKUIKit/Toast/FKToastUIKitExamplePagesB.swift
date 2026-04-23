import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class FKToastSnackbarExampleViewController: FKToastExampleBaseViewController {
  private let announcementSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Snackbar"

    announcementSwitch.isOn = true
    let toggleRow = UIStackView()
    toggleRow.axis = .horizontal
    toggleRow.alignment = .center
    toggleRow.spacing = 8
    let toggleLabel = UILabel()
    toggleLabel.text = "Enable VoiceOver announcement"
    toggleLabel.font = .preferredFont(forTextStyle: .subheadline)
    toggleLabel.adjustsFontForContentSizeCategory = true
    toggleRow.addArrangedSubview(toggleLabel)
    toggleRow.addArrangedSubview(announcementSwitch)

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(toggleRow)
    actions.addArrangedSubview(FKToastExampleUI.row([
      FKToastExampleUI.button("Show Action Snackbar") { [weak self] in
        FKToastExamplePlaybook.showActionSnackbarExample(announcementEnabled: self?.announcementSwitch.isOn ?? true)
      },
      FKToastExampleUI.button("Clear Current") { FKToast.clearAll(animated: true) },
    ]))

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Interactive Snackbar",
        description: "Shows primary and secondary actions, swipe dismiss, accessibility labels, and announcement on/off control.",
        body: actions
      )
    )
  }
}

final class FKToastEnvironmentExampleViewController: FKToastExampleBaseViewController, UITextFieldDelegate {
  private let appearanceSegment = UISegmentedControl(items: ["System", "Light", "Dark"])
  private let keyboardField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Environment"
    buildAppearanceSection()
    buildKeyboardSection()
    buildValidationSection()
  }

  private func buildAppearanceSection() {
    appearanceSegment.selectedSegmentIndex = 0
    appearanceSegment.addAction(UIAction { [weak self] action in
      guard let sender = action.sender as? UISegmentedControl else { return }
      self?.overrideUserInterfaceStyle = sender.selectedSegmentIndex == 1 ? .light : (sender.selectedSegmentIndex == 2 ? .dark : .unspecified)
    }, for: .valueChanged)

    let wrap = UIStackView(arrangedSubviews: [appearanceSegment, FKToastExampleUI.button("Show Adaptive Toast") {
      FKToast.show("Adaptive color and typography preview", style: .normal, kind: .toast)
    }, FKToastExampleUI.row([
      FKToastExampleUI.button("Show Material Blur") { FKToastExamplePlaybook.showVisualEffectExample(liquidPreferred: false) },
      FKToastExampleUI.button("Show Liquid Preferred") { FKToastExamplePlaybook.showVisualEffectExample(liquidPreferred: true) },
    ])])
    wrap.axis = .vertical
    wrap.spacing = 8
    contentStack.addArrangedSubview(FKToastExampleUI.section(
      title: "Light / Dark + Dynamic Type",
      description: "Use iOS Settings > Accessibility > Display & Text Size > Larger Text, then trigger toasts to verify dynamic type, appearance adaptation, and blur fallback behavior.",
      body: wrap
    ))
  }

  private func buildKeyboardSection() {
    keyboardField.borderStyle = .roundedRect
    keyboardField.placeholder = "Tap to open keyboard, then show snackbar"
    keyboardField.delegate = self

    let wrap = UIStackView(arrangedSubviews: [keyboardField, FKToastExampleUI.button("Show Keyboard-Avoiding Snackbar") {
      FKSnackbar.show("Keyboard is visible, snackbar should stay above it.", style: .info)
    }])
    wrap.axis = .vertical
    wrap.spacing = 8
    contentStack.addArrangedSubview(FKToastExampleUI.section(
      title: "Keyboard Avoidance",
      description: "Focus the text field to present the keyboard. The snackbar should reposition above the keyboard.",
      body: wrap
    ))
  }

  private func buildValidationSection() {
    let wrap = UIStackView()
    wrap.axis = .vertical
    wrap.spacing = 8
    wrap.addArrangedSubview(FKToastExampleUI.button("Rotation Check Message") {
      FKToast.show("Rotate device between portrait and landscape while this message appears.", style: .warning, kind: .snackbar)
    })
    wrap.addArrangedSubview(FKToastExampleUI.button("Multi-Scene Verification Hint") {
      FKToast.show("Open a second scene/window and trigger example there; each scene resolves its own top window.", style: .info, kind: .toast)
    })
    contentStack.addArrangedSubview(FKToastExampleUI.section(
      title: "Rotation + Multi Scene",
      description: "For multi-scene testing on iPadOS, create a new window from app switcher and run this example in both windows.",
      body: wrap
    ))
  }
}

final class FKToastSwiftUIHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI Bridge"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKToastSwiftUISurface())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKToastSwiftUISurface: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("SwiftUI uses the same FKToastExamplePlaybook as UIKit.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Button("Basic Placement Example") { FKToastExamplePlaybook.showBasicPlacementAndStyle() }.buttonStyle(.borderedProminent)
        Button("Queue + Coalesce Example") { FKToastExamplePlaybook.burstQueueExample(); FKToastExamplePlaybook.dedupeCoalesceExample() }.buttonStyle(.bordered)
        Button("HUD Progress Example") { FKToastExamplePlaybook.showHUDProgress() }.buttonStyle(.bordered)
        Button("Action Snackbar Example") { FKToastExamplePlaybook.showActionSnackbarExample(announcementEnabled: true) }.buttonStyle(.bordered)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif

