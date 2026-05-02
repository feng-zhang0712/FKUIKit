import UIKit
import FKUIKit

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
