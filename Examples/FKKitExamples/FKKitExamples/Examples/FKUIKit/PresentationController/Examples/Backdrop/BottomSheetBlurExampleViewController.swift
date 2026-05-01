import UIKit
import FKUIKit

/// Demonstrates blur material applied to the bottom-sheet container.
final class BottomSheetBlurExampleViewController: FKPresentationBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Bottom sheet blur",
      subtitle: "Apply blur on the popup container (not the dim backdrop).",
      notes: "Tip: increase contentInsets to expose more container material area."
    )

    applyPreset(.systemSheetLike)
    addSharedBlurControls()

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
      configuration.sheet.detents = [.fixed(300), .fraction(0.6), .full]
      configuration.contentInsets = .init(top: 14, leading: 14, bottom: 14, trailing: 14)
      self.applyCommonBlurConfiguration(to: &configuration)
      let content = FKExampleLabelContentViewController(text: "Bottom sheet blur", usesTransparentBackground: true)
      _ = FKPresentationController.present(
        contentController: content,
        from: self,
        configuration: configuration,
        delegate: nil,
        handlers: .init(),
        animated: true,
        completion: nil
      )
    }
  }
}

