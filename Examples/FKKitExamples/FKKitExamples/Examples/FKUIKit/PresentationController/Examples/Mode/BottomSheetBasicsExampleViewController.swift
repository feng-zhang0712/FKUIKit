import UIKit
import FKUIKit

/// Shows a basic bottom sheet setup with a practical detent ladder.
///
/// Key highlights:
/// - Uses `.bottomSheet` mode with commonly used detents.
/// - Shows the “copy/paste” entry point for most apps.
/// - Includes both `.large` (near-full) and `.full` (true full-screen).
final class BottomSheetBasicsExampleViewController: FKPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Bottom sheet — Basics",
      subtitle: "A practical bottom sheet setup with near-full and full detents.",
      notes: """
      Why this setup is useful:
      - Tap-to-dismiss and swipe-to-dismiss are enabled for a system-like feel.
      - `.large` keeps a visible top gap (system-sheet-like), while `.full` is true full-screen.
      - Safe area policy still follows the selected configuration defaults.
      """
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fitContent, .medium, .large, .full]
      _ = FKPresentationExampleHelpers.present(from: self, title: "Bottom sheet", configuration: configuration)
    }
  }
}

