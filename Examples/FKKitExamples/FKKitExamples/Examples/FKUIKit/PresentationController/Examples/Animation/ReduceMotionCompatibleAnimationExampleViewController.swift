import UIKit
import FKUIKit

/// Shows selecting a gentler animation when Reduce Motion is enabled.
///
/// Key highlights:
/// - Reads `UIAccessibility.isReduceMotionEnabled` at runtime.
/// - Chooses a calmer preset (or disables animation) without any test-only code.
final class ReduceMotionCompatibleAnimationExampleViewController: FKPresentationExamplePageViewController {
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Reduce Motion compatible",
      subtitle: "Use a milder animation when the user requests reduced motion.",
      notes: "This is an accessibility best practice: respect user preference and reduce vestibular discomfort."
    )

    statusLabel.font = .preferredFont(forTextStyle: .callout)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    addView(statusLabel)

    updateStatus()

    addPrimaryButton(title: "Present (auto choose)") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.sheet.detents = [.fixed(300), .full]

      if UIAccessibility.isReduceMotionEnabled {
        configuration.animation.preset = .fade
        configuration.animation.duration = 0.18
      } else {
        configuration.animation.preset = .systemLike
      }

      _ = FKPresentationExampleHelpers.present(from: self, title: "Reduce Motion aware", configuration: configuration)
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(accessibilitySettingsDidChange),
      name: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil
    )
  }

  @objc private func accessibilitySettingsDidChange() {
    updateStatus()
  }

  private func updateStatus() {
    statusLabel.text = "Reduce Motion is \(UIAccessibility.isReduceMotionEnabled ? "ON" : "OFF")."
  }
}

