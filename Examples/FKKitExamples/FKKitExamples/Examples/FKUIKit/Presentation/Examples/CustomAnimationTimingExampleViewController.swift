import UIKit
import FKUIKit

/// Shows explicit tuning of duration / spring parameters.
///
/// Key highlights:
/// - Shows when custom timing is useful (brand motion, complex layout, content density).
/// Caveat:
/// - Avoid overly bouncy springs for accessibility and perceived latency.
final class CustomAnimationTimingExampleViewController: FKPresentationExamplePageViewController {
  private var duration: Float = 0.32
  private var damping: Float = 0.9
  private var response: Float = 0.45

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Custom animation timing",
      subtitle: "Tune duration and spring feel for your UI.",
      notes: """
      When you might customize:
      - Your product has a distinct motion identity.
      - The presented view is heavy and needs a slower, calmer transition.
      - You’re matching a pre-existing animation system.
      """
    )

    addView(FKExampleControls.slider(title: "Duration", value: duration, range: 0.12...0.9, valueText: { String(format: "%.2fs", $0) }) { [weak self] v in
      self?.duration = v
    })

    addView(FKExampleControls.slider(title: "Damping ratio", value: damping, range: 0.3...1.0, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.damping = v
    })

    addView(FKExampleControls.slider(title: "Response", value: response, range: 0.2...0.9, valueText: { String(format: "%.2f", $0) }) { [weak self] v in
      self?.response = v
    })

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var config = FKPresentationConfiguration.default
      config.mode = .bottomSheet
      config.sheet.detents = [.fixed(320), .full]

      config.animation.preset = .spring
      config.animation.duration = TimeInterval(self.duration)
      config.animation.dampingRatio = CGFloat(self.damping)
      config.animation.response = CGFloat(self.response)

      _ = FKPresentationExampleHelpers.present(from: self, title: "Custom timing", configuration: config)
    }
  }
}

