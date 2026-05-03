import UIKit
import FKUIKit

@MainActor
class FKPresentationBlurExampleBaseViewController: FKPresentationExamplePageViewController {
  // MARK: - Tunables (shared)

  var blurEnabled: Bool = true
  var dimAlpha: Float = 0.35

  var backendIndex: Int = 0 // 0: system, 1: custom
  var modeIndex: Int = 0 // 0: dynamic, 1: static

  var styleIndex: Int = 2
  let styles: [FKBlurConfiguration.SystemStyle] = [
    .systemUltraThinMaterial,
    .systemThinMaterial,
    .systemMaterial,
    .systemThickMaterial,
    .systemChromeMaterial,
  ]

  var blurOpacity: Float = 0.95

  // Custom backend params
  var blurRadius: Float = 18
  var saturation: Float = 1.0
  var brightness: Float = 0
  var tintOpacity: Float = 0
  var tintColor: UIColor = .systemBlue

  // MARK: - Presets

  enum Preset: Int {
    case systemSheetLike = 0
    case customVibrant = 1
  }

  func applyPreset(_ preset: Preset) {
    switch preset {
    case .systemSheetLike:
      blurEnabled = true
      dimAlpha = 0.35
      backendIndex = 0
      modeIndex = 0
      styleIndex = 2 // systemMaterial
      blurOpacity = 1.0

      blurRadius = 18
      saturation = 1.0
      brightness = 0
      tintOpacity = 0
      tintColor = .systemBlue

    case .customVibrant:
      blurEnabled = true
      dimAlpha = 0.25
      backendIndex = 1
      modeIndex = 0
      styleIndex = 2
      blurOpacity = 1.0

      blurRadius = 20
      saturation = 1.25
      brightness = 0.04
      tintOpacity = 0.14
      tintColor = .systemBlue
    }
  }

  // MARK: - UI

  func addSharedBlurControls() {
    addView(FKExampleControls.segmented(
      title: "Preset",
      items: ["System sheet-like", "Custom vibrant"],
      selectedIndex: Preset.systemSheetLike.rawValue
    ) { [weak self] idx in
      guard let self, let preset = Preset(rawValue: idx) else { return }
      self.applyPreset(preset)
    })

    addView(FKExampleControls.toggle(title: "Enable blur", isOn: blurEnabled) { [weak self] isOn in
      self?.blurEnabled = isOn
    })
    addView(FKExampleControls.slider(
      title: "Dim alpha",
      value: dimAlpha,
      range: 0...1,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.dimAlpha = value
    })
    addView(FKExampleControls.segmented(
      title: "Backend",
      items: ["System", "Custom"],
      selectedIndex: backendIndex
    ) { [weak self] idx in
      self?.backendIndex = idx
    })
    addView(FKExampleControls.segmented(
      title: "Mode",
      items: ["Dynamic", "Static"],
      selectedIndex: modeIndex
    ) { [weak self] idx in
      self?.modeIndex = idx
    })
    addView(FKExampleControls.segmented(
      title: "Material",
      items: ["UltraThin", "Thin", "Material", "Thick", "Chrome"],
      selectedIndex: styleIndex
    ) { [weak self] idx in
      self?.styleIndex = idx
    })
    addView(FKExampleControls.slider(
      title: "Blur opacity",
      value: blurOpacity,
      range: 0.4...1.0,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.blurOpacity = value
    })

    addSectionTitle("Custom backend parameters")
    addView(FKExampleControls.slider(
      title: "Blur radius",
      value: blurRadius,
      range: 4...36,
      valueText: { String(format: "%.0f", $0) }
    ) { [weak self] value in
      self?.blurRadius = value
    })
    addView(FKExampleControls.slider(
      title: "Saturation",
      value: saturation,
      range: 0.4...1.8,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.saturation = value
    })
    addView(FKExampleControls.slider(
      title: "Brightness",
      value: brightness,
      range: -0.2...0.2,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.brightness = value
    })
    addView(FKExampleControls.slider(
      title: "Tint opacity",
      value: tintOpacity,
      range: 0...0.5,
      valueText: { String(format: "%.2f", $0) }
    ) { [weak self] value in
      self?.tintOpacity = value
    })
  }

  // MARK: - Builders

  func makeBackdropStyle() -> FKBackdropStyle {
    .dim(alpha: CGFloat(dimAlpha))
  }

  func makeBlurConfiguration() -> FKBlurConfiguration {
    let mode: FKBlurConfiguration.Mode = (modeIndex == 0) ? .dynamic : .static
    if backendIndex == 0 {
      return FKBlurConfiguration(
        mode: mode,
        backend: .system(style: styles[styleIndex]),
        opacity: CGFloat(blurOpacity)
      )
    }
    return FKBlurConfiguration(
      mode: mode,
      backend: .custom(parameters: .init(
        blurRadius: CGFloat(blurRadius),
        saturation: CGFloat(saturation),
        brightness: CGFloat(brightness),
        tintColor: tintColor,
        tintOpacity: CGFloat(tintOpacity)
      )),
      opacity: CGFloat(blurOpacity),
      downsampleFactor: 4
    )
  }

  func applyCommonBlurConfiguration(to configuration: inout FKPresentationConfiguration) {
    configuration.backdropStyle = makeBackdropStyle()
    configuration.containerBlur = .init(
      isEnabled: blurEnabled,
      configuration: makeBlurConfiguration()
    )
  }
}

