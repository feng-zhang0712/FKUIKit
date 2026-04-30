import UIKit
import FKUIKit

/// Shows ratio-based detents that adapt across device sizes.
///
/// Key highlights:
/// - Uses `.fraction(0.25)` and `.fraction(0.6)`.
/// - Useful when you want consistent “relative” space usage on iPhone vs iPad.
final class SheetDetentsFractionExampleViewController: FKPresentationExamplePageViewController {
  private var smallFraction: Float = 0.25
  private var largeFraction: Float = 0.6

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Detents — Fraction",
      subtitle: "Detents based on a fraction of available height.",
      notes: "Fractions are a good fit for adaptive layouts and split view environments."
    )

    addView(
      FKExampleControls.slider(
        title: "Small fraction",
        value: smallFraction,
        range: 0.15...0.5,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.smallFraction = v
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Large fraction",
        value: largeFraction,
        range: 0.35...0.95,
        valueText: { String(format: "%.2f", $0) }
      ) { [weak self] v in
        self?.largeFraction = v
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.sheet.detents = [.fraction(CGFloat(self.smallFraction)), .fraction(CGFloat(self.largeFraction))]
      configuration.sheet.initialDetentIndex = 0
      _ = FKPresentationExampleHelpers.present(from: self, title: "Fraction detents", configuration: configuration)
    }
  }
}

