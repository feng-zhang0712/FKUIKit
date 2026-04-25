import UIKit
import FKUIKit

/// Shows a liquid-glass backdrop request on iOS 26+ with automatic downgrade.
///
/// Key highlights:
/// - Requests `FKBackdropStyle.liquidGlass` when available.
/// - Falls back to blur on earlier iOS versions and shows the active choice in UI.
/// Caveat:
/// - Reduce Transparency and Low Power Mode may downgrade/simplify effects for accessibility/performance.
final class LiquidGlassBackdropExampleViewController: FKPresentationExamplePageViewController {
  private let resolvedStyleLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Liquid Glass (iOS 26+)",
      subtitle: "Request liquid glass when supported; show fallback otherwise.",
      notes: "This page shows the chosen style before presenting so users understand what will happen on their device."
    )

    resolvedStyleLabel.font = .preferredFont(forTextStyle: .callout)
    resolvedStyleLabel.textColor = .secondaryLabel
    resolvedStyleLabel.numberOfLines = 0
    addView(resolvedStyleLabel)
    updateResolvedStyleLabel()

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.mode = .bottomSheet
      configuration.sheet.detents = [.fixed(300), .full]
      configuration.backdrop.style = self.resolvedBackdropStyle()
      _ = FKPresentationExampleHelpers.present(from: self, title: "Backdrop style", configuration: configuration)
    }
  }

  private func resolvedBackdropStyle() -> FKBackdropStyle {
    // The public API allows requesting liquid glass, but also expects the system to downgrade when needed.
    // This example makes the choice explicit so users can copy it into production code.
    if #available(iOS 26.0, *) {
      if UIAccessibility.isReduceTransparencyEnabled {
        return .blur(effect: .systemMaterial, alpha: 1, vibrancy: nil)
      }
      return .liquidGlass(configuration: .init(intensity: 1, showsNoise: true, showsHighlight: true))
    } else {
      return .blur(effect: .systemMaterial, alpha: 1, vibrancy: nil)
    }
  }

  private func updateResolvedStyleLabel() {
    let text: String
    if #available(iOS 26.0, *) {
      text = UIAccessibility.isReduceTransparencyEnabled ? "Resolved: Fallback Blur (Reduce Transparency enabled)" : "Resolved: Liquid Glass"
    } else {
      text = "Resolved: Fallback Blur (iOS < 26)"
    }
    resolvedStyleLabel.text = text
  }
}

