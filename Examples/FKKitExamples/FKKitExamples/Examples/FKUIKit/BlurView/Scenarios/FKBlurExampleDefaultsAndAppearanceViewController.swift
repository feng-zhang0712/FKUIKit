import UIKit
import FKUIKit

// MARK: - Scenario: Global Defaults

final class FKBlurGlobalConfigVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global Defaults"

    let apply = UIButton(type: .system)
    apply.setTitle("Apply global default (systemThinMaterial + 0.9)", for: .normal)
    apply.addAction(UIAction { _ in
      FKBlur.defaultConfiguration = FKBlurConfiguration(
        backend: .system(style: .systemThinMaterial),
        opacity: 0.9
      )
    }, for: .touchUpInside)

    let create = UIButton(type: .system)
    create.setTitle("Create a FKBlurView using global default", for: .normal)
    create.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let bg = FKBlurExampleUI.makeColorfulBackgroundView(height: 130)
      let blur = FKBlurView() // Uses FKBlur.defaultConfiguration as the baseline
      blur.maskedCornerRadius = 16
      FKBlurExampleUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 240, height: 74))
      FKBlurExampleUI.addOverlayText(to: blur, text: "From global default")
      self.stack.addArrangedSubview(bg)
    }, for: .touchUpInside)

    let reset = UIButton(type: .system)
    reset.setTitle("Reset global default", for: .normal)
    reset.addAction(UIAction { _ in
      FKBlur.defaultConfiguration = .default
    }, for: .touchUpInside)

    let col = UIStackView(arrangedSubviews: [apply, create, reset])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "FKBlur.defaultConfiguration",
      description: "Set once at app launch to unify style; override per view when needed.",
      content: col
    ))
  }
}

// MARK: - Scenario: Dark Mode

final class FKBlurDarkModeVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark Mode"

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

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // System materials automatically adapt to Light/Dark.
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blur.maskedCornerRadius = 16
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "Switch appearance")

    let col = UIStackView(arrangedSubviews: [seg, bg])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "Light / Dark",
      description: "Switch the segmented control to preview adaptive system materials.",
      content: col
    ))
  }
}

// MARK: - Scenario: Rotation

final class FKBlurRotationVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rotation"

    let hint = UILabel()
    hint.text = "Rotate the device/simulator: the blur view will relayout (and refresh if needed)."
    hint.numberOfLines = 0
    hint.textColor = .secondaryLabel

    let bg = FKBlurExampleUI.makeColorfulBackgroundView(height: 220)
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemChromeMaterial))
    blur.maskedCornerRadius = 20
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 280, height: 110))
    FKBlurExampleUI.addOverlayText(to: blur, text: "Rotation-ready")

    let col = UIStackView(arrangedSubviews: [hint, bg])
    col.axis = .vertical
    col.spacing = 10
    stack.addArrangedSubview(col)
  }
}
