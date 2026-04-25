import UIKit
import FKUIKit

/// Shows swipe-to-dismiss toggling and how thresholds change the “cancellation feel”.
///
/// Key highlights:
/// - Toggle `allowsSwipeToDismiss`.
/// - Tune `sheet.dismissThreshold` and `sheet.dismissVelocityThreshold`.
/// Caveat:
/// - Thresholds are UX-sensitive. Tune with real content, not placeholder views.
final class SwipeToDismissExampleViewController: FKPresentationExamplePageViewController {
  private var swipeToDismiss = true
  private var dismissThreshold: Float = 44
  private var velocityThreshold: Float = 1200

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Swipe to dismiss on/off",
      subtitle: "Compare how thresholds influence finish vs cancel.",
      notes: "Lower thresholds dismiss easier; higher thresholds reduce accidental dismissal during scrolling."
    )

    addView(
      FKExampleControls.toggle(title: "Allows swipe to dismiss", isOn: swipeToDismiss) { [weak self] isOn in
        self?.swipeToDismiss = isOn
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Dismiss threshold (points)",
        value: dismissThreshold,
        range: 8...120,
        valueText: { "\(Int($0)) pt" }
      ) { [weak self] v in
        self?.dismissThreshold = v
      }
    )

    addView(
      FKExampleControls.slider(
        title: "Velocity threshold",
        value: velocityThreshold,
        range: 300...2400,
        valueText: { "\(Int($0))" }
      ) { [weak self] v in
        self?.velocityThreshold = v
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var config = FKPresentationConfiguration.default
      config.mode = .bottomSheet
      config.allowsSwipeToDismiss = self.swipeToDismiss
      config.sheet.dismissThreshold = CGFloat(self.dismissThreshold)
      config.sheet.dismissVelocityThreshold = CGFloat(self.velocityThreshold)
      config.sheet.detents = [.fixed(260), .full]
      _ = FKPresentationExampleHelpers.present(from: self, title: "Swipe to dismiss", configuration: config)
    }
  }
}

