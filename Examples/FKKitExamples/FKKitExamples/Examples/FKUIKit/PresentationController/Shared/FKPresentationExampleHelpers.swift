import UIKit
import FKUIKit

enum FKPresentationExampleHelpers {
  @MainActor
  static func present(
    from presentingViewController: UIViewController,
    title: String,
    configuration: FKPresentationConfiguration,
    callbacks: FKPresentationControllerLifecycleCallbacks = .init()
  ) -> FKPresentationController {
    let content = FKExampleLabelContentViewController(text: title)
    content.title = title
    return FKPresentationController.present(
      contentController: content,
      from: presentingViewController,
      configuration: configuration,
      delegate: nil,
      callbacks: callbacks,
      animated: true,
      completion: nil
    )
  }
}

