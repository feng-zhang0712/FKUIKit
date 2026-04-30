import UIKit
import FKUIKit

/// Uses interactive progress callbacks to drive UI updates.
///
/// Key highlights:
/// - `FKPresentationLifecycleHandlers.progress` updates a label in real time.
/// - A common use case is to synchronize backdrop or chrome with dismiss progress.
final class InteractiveDismissProgressExampleViewController: FKPresentationExamplePageViewController {
  private let progressLabel = UILabel()
  private var activePresentation: FKPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Interactive dismiss progress callback",
      subtitle: "Drive your own UI from interactive dismiss progress.",
      notes: "This example updates a label, but you can also map progress to blur/dim intensity or scale effects."
    )

    progressLabel.font = .preferredFont(forTextStyle: .title3)
    progressLabel.textColor = .label
    progressLabel.textAlignment = .center
    progressLabel.text = "Progress: 0.00"
    addView(progressLabel)

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }

      let callbacks = FKPresentationLifecycleHandlers(
        willDismiss: { [weak self] in
          // Capture weakly: callbacks are retained by the presentation controller during transitions.
          self?.progressLabel.text = "Progress: 0.00"
        },
        didDismiss: { [weak self] in
          self?.activePresentation = nil
        },
        progress: { [weak self] progress in
          self?.progressLabel.text = String(format: "Progress: %.2f", progress)
        }
      )

      var configuration = FKPresentationConfiguration.default
      configuration.layout = .bottomSheet(configuration.sheet)
      configuration.sheet.detents = [.fixed(320), .full]
      configuration.backdropStyle = .dim(alpha: 0.4)

      self.activePresentation = FKPresentationExampleHelpers.present(
        from: self,
        title: "Drag to dismiss",
        configuration: configuration,
        handlers: callbacks
      )
    }
  }
}

