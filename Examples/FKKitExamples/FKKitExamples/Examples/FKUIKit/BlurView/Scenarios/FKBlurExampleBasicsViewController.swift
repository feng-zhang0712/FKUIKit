import UIKit
import FKUIKit

// MARK: - Scenario: Basic Blur

final class FKBlurBasicVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic Blur View"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // Minimal usage: initialize and add to view hierarchy.
    // It uses `FKBlur.defaultConfiguration` as the baseline (systemMaterial by default).
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur)

    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "One-line setup",
      description: "let blur = FKBlurView() // default systemMaterial\nGreat for: cards, headers, overlays.",
      content: bg
    ))
  }
}

// MARK: - Scenario: All System Styles

final class FKBlurAllSystemStylesVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "All System Styles"

    // System materials are hardware accelerated and the recommended choice for dynamic content.
    FKBlurConfiguration.SystemStyle.allCases.forEach { style in
      let bg = FKBlurExampleUI.makeColorfulBackgroundView(height: 130)
      let blur = FKBlurView()
      blur.configuration = FKBlurConfiguration(backend: .system(style: style))
      FKBlurExampleUI.embedCenteredBlurView(blur, on: bg, size: .init(width: 240, height: 74))
      FKBlurExampleUI.addOverlayText(to: blur, text: "style: \(style)")
      stack.addArrangedSubview(FKBlurExampleUI.card(
        title: "\(style)",
        description: "Built-in system material (`UIBlurEffect.Style`). Best for dynamic scenarios.",
        content: bg
      ))
    }
  }
}
