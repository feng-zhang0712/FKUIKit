import UIKit
import FKUIKit

/// Shows the simplest bottom sheet presentation using `FKPresentationController` defaults.
///
/// Key highlights:
/// - Uses `.bottomSheet` + `.default` configuration.
/// - Shows the “copy/paste” entry point for most apps.
/// - Notes when defaults are a good fit (and when you should customize).
final class BottomSheetBasicsExampleViewController: FKPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Bottom sheet — Basics",
      subtitle: "The fastest way to present a bottom sheet with FK defaults.",
      notes: """
      Why this is a good default:
      - Tap-to-dismiss and swipe-to-dismiss are enabled for a system-like feel.
      - Detents default to fitContent + full.
      - Safe area policy defaults to content-respects-safe-area (edge-attached look).
      """
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      let configuration = FKPresentationConfiguration.default
      _ = FKPresentationExampleHelpers.present(from: self, title: "Bottom sheet", configuration: configuration)
    }
  }
}

