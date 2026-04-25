import UIKit
import FKUIKit

/// Shows a dim backdrop and alpha tuning.
///
/// Key highlights:
/// - Adjust alpha with a slider.
/// - Explains the trade-off between focus (higher alpha) and context visibility (lower alpha).
final class DimBackdropExampleViewController: FKPresentationExamplePageViewController {
  private var alpha: Float = 0.35

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Dim backdrop",
      subtitle: "A simple, readable backdrop with adjustable intensity.",
      notes: "Higher alpha increases focus on the sheet but reduces context visibility behind it."
    )

    addView(
      FKExampleControls.slider(
        title: "Dim alpha",
        value: alpha,
        range: 0.05...0.8,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.alpha = v
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var config = FKPresentationConfiguration.default
      config.mode = .bottomSheet
      config.sheet.detents = [.fixed(300), .full]
      config.backdrop.style = .dim(alpha: CGFloat(self.alpha))
      _ = FKPresentationExampleHelpers.present(from: self, title: "Dim backdrop", configuration: config)
    }
  }
}

