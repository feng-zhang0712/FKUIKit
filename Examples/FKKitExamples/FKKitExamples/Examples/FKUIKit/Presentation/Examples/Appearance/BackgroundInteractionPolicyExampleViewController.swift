import UIKit
import FKUIKit

/// Shows allowing background interaction while a presentation is visible.
///
/// Key highlights:
/// - `backgroundInteraction.isEnabled` enables touch passthrough (advanced).
/// Caveat:
/// - This can be risky: users may trigger underlying UI unintentionally. Use with care.
final class BackgroundInteractionPolicyExampleViewController: FKPresentationExamplePageViewController {
  private var allowsBackgroundInteraction: Bool = false
  private var showsBackdropWhenEnabled: Bool = true

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Background interaction policy",
      subtitle: "Allow or block touches to the presenting UI.",
      notes: "Enabling passthrough is powerful for overlays, but it can create confusing touch layering if overused."
    )

    addView(
      FKExampleControls.toggle(
        title: "Allow background interaction (passthrough)",
        isOn: allowsBackgroundInteraction
      ) { [weak self] isOn in
        self?.allowsBackgroundInteraction = isOn
      }
    )

    addView(
      FKExampleControls.toggle(
        title: "Show backdrop when interaction is enabled",
        isOn: showsBackdropWhenEnabled
      ) { [weak self] isOn in
        self?.showsBackdropWhenEnabled = isOn
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.mode = .center
      configuration.center.allowsSwipeToDismiss = true

      configuration.backgroundInteraction.isEnabled = self.allowsBackgroundInteraction
      configuration.backgroundInteraction.showsBackdropWhenEnabled = self.showsBackdropWhenEnabled

      // When allowing background interaction, consider disabling tap-to-dismiss to avoid surprising dismissal.
      configuration.allowsTapToDismiss = !self.allowsBackgroundInteraction
      configuration.backdrop.style = .dim(alpha: 0.25)

      _ = FKPresentationExampleHelpers.present(from: self, title: "Background interaction", configuration: configuration)
    }
  }
}

