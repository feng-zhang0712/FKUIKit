import UIKit
import FKUIKit

/// Uses fixed-point detents and demonstrates programmatic detent switching.
///
/// Key highlights:
/// - Two fixed detents (`.fixed(240)`, `.fixed(520)`).
/// - Uses `FKPresentationController.setDetent(_:animated:)` from outside the presented controller.
final class SheetDetentsPointsExampleViewController: FKPresentationExamplePageViewController {
  private var currentController: FKPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Detents — Points",
      subtitle: "Two fixed heights plus buttons to switch detents programmatically.",
      notes: "Programmatic detent switching is useful for guided flows (e.g. expanding after validation)."
    )

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(240), .fixed(520)]
      configuration.sheet.initialDetentIndex = 0
      self.currentController = FKPresentationExampleHelpers.present(from: self, title: "Points detents", configuration: configuration)
    }

    addView(
      FKExampleControls.toggle(
        title: "Keep a reference to call setDetent",
        isOn: true
      ) { _ in }
    )

    addPrimaryButton(title: "Switch to 240pt") { [weak self] in
      self?.currentController?.setDetent(.fixed(240), animated: true)
    }

    addPrimaryButton(title: "Switch to 520pt") { [weak self] in
      self?.currentController?.setDetent(.fixed(520), animated: true)
    }
  }
}

