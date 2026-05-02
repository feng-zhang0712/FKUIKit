import UIKit
import FKUIKit

// MARK: - Scenario: Custom Parameters (Radius / Saturation / Brightness / Tint)

final class FKBlurCustomRadiusVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Blur Radius"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // The custom backend provides full control via Core Image (Metal accelerated when available).
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 10, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "blurRadius: 10")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "blurRadius = 10",
      description: "Example value. Adjust blurRadius as needed.",
      content: bg
    ))

    let bg2 = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 28, saturation: 1.0, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurExampleUI.addOverlayText(to: blur2, text: "blurRadius: 28")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "blurRadius = 28",
      description: "Larger radius produces fewer background details.",
      content: bg2
    ))
  }
}

final class FKBlurCustomSaturationVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Saturation"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 0.6, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "saturation: 0.6")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "saturation = 0.6 (desaturated)",
      description: "Often used for a softer, calmer background material.",
      content: bg
    ))

    let bg2 = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.4, brightness: 0.0, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurExampleUI.addOverlayText(to: blur2, text: "saturation: 1.4")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "saturation = 1.4 (more vivid)",
      description: "Often used for a more vibrant material look.",
      content: bg2
    ))
  }
}

final class FKBlurCustomBrightnessVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Brightness"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    let params = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.0, brightness: -0.10, tintColor: nil, tintOpacity: 0)
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "brightness: -0.10")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "brightness = -0.10 (darker)",
      description: "Use brightness to tune the overall mood.",
      content: bg
    ))

    let bg2 = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur2 = FKBlurView()
    let params2 = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.0, brightness: 0.12, tintColor: nil, tintOpacity: 0)
    blur2.configuration = FKBlurConfiguration(backend: .custom(parameters: params2), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur2, on: bg2)
    FKBlurExampleUI.addOverlayText(to: blur2, text: "brightness: 0.12")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "brightness = 0.12 (brighter)",
      description: "A brighter, hazier look for light backgrounds.",
      content: bg2
    ))
  }
}

final class FKBlurCustomTintVC: FKBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Tint Overlay"

    let bg = FKBlurExampleUI.makeColorfulBackgroundView()
    let blur = FKBlurView()
    // tintColor + tintOpacity adds a simple overlay, useful for brand/theme-tinted materials.
    let params = FKBlurConfiguration.CustomParameters(
      blurRadius: 18,
      saturation: 1.0,
      brightness: 0.0,
      tintColor: .systemIndigo,
      tintOpacity: 0.18
    )
    blur.configuration = FKBlurConfiguration(backend: .custom(parameters: params), downsampleFactor: 4)
    FKBlurExampleUI.embedCenteredBlurView(blur, on: bg)
    FKBlurExampleUI.addOverlayText(to: blur, text: "tint: indigo (0.18)")
    stack.addArrangedSubview(FKBlurExampleUI.card(
      title: "tintColor + tintOpacity",
      description: "Apply a tint overlay to quickly get a brand/theme feel.",
      content: bg
    ))
  }
}

