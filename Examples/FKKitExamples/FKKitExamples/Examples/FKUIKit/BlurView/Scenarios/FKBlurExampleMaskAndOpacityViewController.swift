import UIKit
import FKUIKit

// MARK: - Scenario: Rounded / Circle / Custom Mask

final class FKBlurRoundedRectVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rounded Rect Blur"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
    blur.maskedCornerRadius = 18 // Rounded blur region using a mask
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "cornerRadius: 18")

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "maskedCornerRadius",
      description: "Great for cards, sheets, dialogs, and overlays.",
      content: bg
    ))
  }
}

final class FKBlurCircleVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Circular Blur"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemUltraThinMaterial))
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 120, height: 120))
    FKBlurExampleUI.addOverlayText(to: blur, text: "Circle")

    // Use maskPath for a circle (update after layout so it matches final bounds).
    blur.fk_onLayout { [weak blur] in
      guard let blur else { return }
      blur.maskPath = UIBezierPath(ovalIn: blur.bounds)
    }

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "maskPath = ovalInRect",
      description: "Great for avatar backplates and circular buttons.",
      content: bg
    ))
  }
}

final class FKBlurCustomMaskVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Mask"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(backend: .system(style: .systemThinMaterial))
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 220, height: 120))
    FKBlurExampleUI.addOverlayText(to: blur, text: "Arbitrary maskPath")

    // Example: a “ticket” shape (two circular notches on left and right).
    blur.fk_onLayout { [weak blur] in
      guard let blur else { return }
      let r = blur.bounds
      let notchRadius: CGFloat = 14
      let path = UIBezierPath(roundedRect: r, cornerRadius: 18)
      path.append(UIBezierPath(ovalIn: CGRect(x: -notchRadius, y: (r.height - notchRadius * 2) / 2, width: notchRadius * 2, height: notchRadius * 2)))
      path.append(UIBezierPath(ovalIn: CGRect(x: r.width - notchRadius, y: (r.height - notchRadius * 2) / 2, width: notchRadius * 2, height: notchRadius * 2)))
      blur.maskPath = path
    }

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "maskPath (arbitrary shape)",
      description: "Useful for tickets, bubbles, and custom-shaped cards.",
      content: bg
    ))
  }
}

// MARK: - Scenario: Semi-Transparent Blur

final class FKBlurOpacityVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Semi-Transparent Blur"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()

    let blur = FKBlurView()
    blur.configuration = FKBlurConfiguration(
      backend: .system(style: .systemMaterial),
      opacity: 0.55 // Overall opacity for a lighter haze look
    )
    blur.maskedCornerRadius = 16
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "opacity: 0.55")

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "opacity",
      description: "Control overall transparency via configuration.opacity.",
      content: bg
    ))
  }
}
