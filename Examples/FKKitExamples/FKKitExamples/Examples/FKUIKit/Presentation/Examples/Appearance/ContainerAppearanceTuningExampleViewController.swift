import UIKit
import FKUIKit

/// Tunes corner radius, shadow, and border using live sliders.
///
/// Key highlights:
/// - Corner radius, shadow opacity/radius, and border width.
/// Caveat:
/// - Large shadows and big corner radii can increase rendering cost; test on older devices.
final class ContainerAppearanceTuningExampleViewController: FKPresentationExamplePageViewController {
  private var cornerRadius: Float = 16
  private var shadowOpacity: Float = 0.18
  private var shadowRadius: Float = 16
  private var borderEnabled: Bool = false
  private var borderWidth: Float = 1

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Corner radius / shadow / border",
      subtitle: "Visual tuning without re-implementing any internals.",
      notes: "These controls are intentionally simple so you can copy them into your own debug panels."
    )

    addView(FKExampleControls.slider(title: "Corner radius", value: cornerRadius, range: 0...28, valueText: { "\(Int($0)) pt" }) { [weak self] v in
      self?.cornerRadius = v
    })

    addView(FKExampleControls.slider(title: "Shadow opacity", value: shadowOpacity, range: 0...0.6, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.shadowOpacity = v
    })

    addView(FKExampleControls.slider(title: "Shadow radius", value: shadowRadius, range: 0...28, valueText: { "\(Int($0)) pt" }) { [weak self] v in
      self?.shadowRadius = v
    })

    addView(FKExampleControls.toggle(title: "Border enabled", isOn: borderEnabled) { [weak self] isOn in
      self?.borderEnabled = isOn
    })

    addView(FKExampleControls.slider(title: "Border width", value: borderWidth, range: 0...3, valueText: { String(format: "%.1f pt", $0) }) { [weak self] v in
      self?.borderWidth = v
    })

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.mode = .bottomSheet
      configuration.sheet.detents = [.fixed(320), .full]

      configuration.cornerRadius = CGFloat(self.cornerRadius)
      configuration.shadow.opacity = self.shadowOpacity
      configuration.shadow.radius = CGFloat(self.shadowRadius)
      configuration.border.isEnabled = self.borderEnabled
      configuration.border.width = CGFloat(self.borderWidth)

      _ = FKPresentationExampleHelpers.present(from: self, title: "Appearance", configuration: configuration)
    }
  }
}

