import UIKit
import FKUIKit

/// A gallery for built-in animation presets.
///
/// Key highlights:
/// - Switch between presets and immediately feel the difference.
/// Caveat:
/// - Pick a preset that matches your product’s motion language and accessibility needs.
final class AnimationPresetGalleryExampleViewController: FKPresentationExamplePageViewController {
  private var presetIndex: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Animation preset gallery",
      subtitle: "Compare built-in presets with one tap.",
      notes: "Present multiple times after switching presets to compare motion."
    )

    addView(
      FKExampleControls.segmented(
        title: "Preset",
        items: ["systemLike", "spring", "easeInOut", "fade", "none"],
        selectedIndex: presetIndex
      ) { [weak self] idx in
        self?.presetIndex = idx
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.sheet.detents = [.fixed(300), .full]

      configuration.animation.preset = {
        switch self.presetIndex {
        case 0: return .systemLike
        case 1: return .spring
        case 2: return .easeInOut
        case 3: return .fade
        default: return .none
        }
      }()

      _ = FKPresentationExampleHelpers.present(from: self, title: "Animation preset", configuration: configuration)
    }
  }
}

