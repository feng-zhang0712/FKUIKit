import UIKit
import FKUIKit

/// Shows blur backdrop styles and performance-minded defaults.
///
/// Key highlights:
/// - Switch between common `UIBlurEffect.Style` values.
/// Caveat:
/// - Heavy blur styles can be expensive in complex view hierarchies. Prefer simpler materials when possible.
final class BlurBackdropExampleViewController: FKPresentationExamplePageViewController {
  private var styleIndex: Int = 0
  private var alpha: Float = 1.0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Blur backdrop",
      subtitle: "A material blur that keeps context visible.",
      notes: "If you notice frame drops in your app, test different materials and lower alpha."
    )

    addView(
      FKExampleControls.segmented(
        title: "Blur style",
        items: ["systemMaterial", "systemThinMaterial", "systemThickMaterial"],
        selectedIndex: styleIndex
      ) { [weak self] idx in
        self?.styleIndex = idx
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Backdrop alpha",
        value: alpha,
        range: 0.2...1.0,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.alpha = v
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let style: UIBlurEffect.Style = {
        switch self.styleIndex {
        case 1: return .systemThinMaterial
        case 2: return .systemThickMaterial
        default: return .systemMaterial
        }
      }()

      var configuration = FKPresentationConfiguration.default
      configuration.mode = .bottomSheet
      configuration.sheet.detents = [.fixed(300), .full]
      configuration.backdrop.style = .blur(effect: style, alpha: CGFloat(self.alpha), vibrancy: nil)
      _ = FKPresentationExampleHelpers.present(from: self, title: "Blur backdrop", configuration: configuration)
    }
  }
}

