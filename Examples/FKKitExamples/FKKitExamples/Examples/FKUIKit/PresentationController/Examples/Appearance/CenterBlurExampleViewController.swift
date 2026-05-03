import UIKit
import FKUIKit

/// Demonstrates blur material applied to the center-modal container.
final class CenterBlurExampleViewController: FKPresentationBlurExampleBaseViewController {
  private enum SizeChoice: Int { case compact, large }
  private var sizeChoice: SizeChoice = .compact

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Center blur",
      subtitle: "A floating center modal with container blur material.",
      notes: "Tip: center modals usually look best with a slightly lower dim alpha than sheets."
    )

    applyPreset(.systemSheetLike)
    dimAlpha = 0.25

    addView(FKExampleControls.segmented(
      title: "Size",
      items: ["320×420", "460×640"],
      selectedIndex: sizeChoice.rawValue
    ) { [weak self] idx in
      self?.sizeChoice = SizeChoice(rawValue: idx) ?? .compact
    })

    addSharedBlurControls()

    addPrimaryButton(title: "Present") { [weak self] in
      guard let self else { return }
      var configuration = FKPresentationConfiguration.default
      configuration.layout = .center(configuration.center)
      configuration.center.size = {
        switch self.sizeChoice {
        case .compact: return .fixed(.init(width: 320, height: 420))
        case .large: return .fixed(.init(width: 460, height: 640))
        }
      }()
      self.applyCommonBlurConfiguration(to: &configuration)

      let content = FKExampleLabelContentViewController(text: "Center blur", usesTransparentBackground: true)
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

