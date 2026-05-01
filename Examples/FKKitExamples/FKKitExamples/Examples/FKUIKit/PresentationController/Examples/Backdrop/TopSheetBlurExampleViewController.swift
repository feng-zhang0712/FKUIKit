import UIKit
import FKUIKit

/// Demonstrates blur material applied to the top-sheet container.
final class TopSheetBlurExampleViewController: FKPresentationBlurExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Top sheet blur",
      subtitle: "Apply blur on the popup itself for a tray-like material.",
      notes: "This blur is on the sheet container, while dim remains controlled by backdropStyle."
    )

    applyPreset(.systemSheetLike)
    addSharedBlurControls()

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationExampleHelpers.topSheetConfiguration()
      configuration.sheet.detents = [.fixed(280), .fraction(0.55), .full]
      configuration.contentInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
      self.applyCommonBlurConfiguration(to: &configuration)
      let content = FKExampleLabelContentViewController(text: "Top sheet blur", usesTransparentBackground: true)
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

