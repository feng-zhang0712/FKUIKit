import UIKit
import FKUIKit

enum FKPresentationExampleHelpers {
  /// Returns the default sheet configuration used by most examples.
  @MainActor
  static func bottomSheetConfiguration() -> FKPresentationConfiguration {
    FKPresentationConfiguration.default
  }

  /// Returns a top-sheet configuration while preserving default sheet tuning.
  @MainActor
  static func topSheetConfiguration() -> FKPresentationConfiguration {
    var configuration = FKPresentationConfiguration.default
    configuration.layout = .topSheet(configuration.sheet)
    return configuration
  }

  @MainActor
  static func present(
    from presentingViewController: UIViewController,
    title: String,
    configuration: FKPresentationConfiguration,
    handlers: FKPresentationLifecycleHandlers = .init()
  ) -> FKPresentationController {
    let content = FKExampleLabelContentViewController(text: title)
    content.title = title
    return FKPresentationController.present(
      contentController: content,
      from: presentingViewController,
      configuration: configuration,
      delegate: nil,
      handlers: handlers,
      animated: true,
      completion: nil
    )
  }
}

