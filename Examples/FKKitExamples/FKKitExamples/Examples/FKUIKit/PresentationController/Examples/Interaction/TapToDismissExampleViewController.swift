import UIKit
import FKUIKit

/// Shows tap-to-dismiss behavior and when you might disable it.
///
/// Key highlights:
/// - Toggle `dismissBehavior.allowsTapOutside`.
/// Caveat:
/// - If your sheet contains destructive actions, consider disabling tap-to-dismiss to reduce accidental loss.
final class TapToDismissExampleViewController: FKPresentationExamplePageViewController {
  private var tapToDismiss = true

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Tap to dismiss on/off",
      subtitle: "Tap outside to dismiss can be convenient, but not always safe.",
      notes: "Disable tap-to-dismiss for flows where accidental dismissal is costly (payments, multi-step forms)."
    )

    addView(
      FKExampleControls.toggle(title: "Allows tap to dismiss", isOn: tapToDismiss) { [weak self] isOn in
        self?.tapToDismiss = isOn
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.dismissBehavior.allowsTapOutside = self.tapToDismiss
      configuration.sheet.detents = [.fixed(260), .full]
      _ = FKPresentationExampleHelpers.present(from: self, title: "Tap outside backdrop", configuration: configuration)
    }
  }
}

