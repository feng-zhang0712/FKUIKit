import UIKit
import FKUIKit

/// Shows `.contentRespectsSafeArea`.
///
/// Key highlights:
/// - The container can attach to screen edges (sheet-like).
/// - Inner content insets are responsible for avoiding notch / home indicator areas.
/// Caveat:
/// - Prefer this for edge-attached sheets; for card-like overlays use `.containerRespectsSafeArea`.
final class SafeAreaContentRespectsSafeAreaExampleViewController: FKPresentationExamplePageViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Safe area — contentRespectsSafeArea",
      subtitle: "Edge-attached container; content manages safe area insets.",
      notes: "Best observed on devices with a notch and a home indicator."
    )

    addPrimaryButton(title: "Present (bottom sheet)") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.safeAreaPolicy = .contentRespectsSafeArea
      configuration.sheet.detents = [.fraction(0.35), .full]
      _ = FKPresentationExampleHelpers.present(from: self, title: "contentRespectsSafeArea", configuration: configuration)
    }
  }
}

