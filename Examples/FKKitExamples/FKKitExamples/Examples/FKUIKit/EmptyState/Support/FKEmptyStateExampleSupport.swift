import FKUIKit
import UIKit

enum FKEmptyStateExampleFactory {
  static func configureGlobalStyleIfNeeded() {
    FKEmptyState.configureDefault { config in
      config.backgroundColor = .systemBackground
      config.titleColor = .label
      config.descriptionColor = .secondaryLabel
      config.titleFont = .systemFont(ofSize: 20, weight: .semibold)
      config.descriptionFont = .systemFont(ofSize: 15, weight: .regular)
      config.verticalSpacing = 12
      config.contentInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
      config.buttonStyle = FKEmptyStateButtonStyle(
        title: nil,
        titleColor: .white,
        font: .systemFont(ofSize: 15, weight: .semibold),
        backgroundColor: .systemBlue,
        cornerRadius: 12,
        contentInsets: UIEdgeInsets(top: 11, left: 18, bottom: 11, right: 18)
      )
    }
  }

  static func makeBasicModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noFavorites)
    model.image = UIImage(systemName: "tray")
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "create", title: "Create item", kind: .primary)
    )
    model.isButtonHidden = false
    return model
  }

  static func makeNoNetworkModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.noNetwork)
    model.image = UIImage(systemName: "wifi.exclamationmark")
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "check_network", title: "Check network", kind: .primary),
      secondary: FKEmptyStateAction(id: "open_docs", title: "Open docs", kind: .secondary)
    )
    model.isButtonHidden = false
    return model
  }

  static func makeLoadFailedModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(.loadFailed)
    model.image = UIImage(systemName: "exclamationmark.arrow.trianglehead.clockwise")
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "retry", title: "Retry", kind: .primary)
    )
    model.isButtonHidden = false
    return model
  }

  static func makeCustomEmptyModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration(
      phase: .empty,
      image: UIImage(systemName: "shippingbox"),
      title: "No Items Yet",
      description: "Create your first item and it will appear here.",
      buttonStyle: FKEmptyStateButtonStyle(title: "Create Item"),
      isButtonHidden: false
    )
    model.titleColor = .systemIndigo
    model.descriptionColor = .systemGray
    model.buttonStyle.backgroundColor = .systemIndigo
    return model
  }

  static func makeMaintenanceModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.customState(
      identifier: "maintenance",
      title: "Service Under Maintenance",
      description: "We are upgrading the service. Please try again later.",
      buttonTitle: "Refresh Status"
    )
    model.image = UIImage(systemName: "wrench.and.screwdriver")
    model.isButtonHidden = false
    model.contentAlignment = .top
    model.verticalOffset = 40
    return model
  }

  static func makeLongTextModel() -> FKEmptyStateConfiguration {
    var model = makeBasicModel()
    model.title = "No content found in the selected workspace and organization scope"
    model.description = "This state demonstrates long text wrapping behavior on compact widths. It should remain readable in portrait mode, split view mode, and with larger Dynamic Type settings."
    return model
  }

  static func makeIconOnlyModel() -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration()
    model.phase = .empty
    model.type = .empty
    model.image = UIImage(systemName: "sparkles")
    model.isTitleHidden = true
    model.isDescriptionHidden = true
    model.isButtonHidden = true
    return model
  }
}

extension UIViewController {
  func fk_presentMessageAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  func fk_embedFill(_ subview: UIView, in container: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: container.topAnchor),
      subview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      subview.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  func fk_makeSectionContainer() -> UIView {
    let container = UIView()
    container.backgroundColor = .secondarySystemBackground
    container.layer.cornerRadius = 12
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }
}
