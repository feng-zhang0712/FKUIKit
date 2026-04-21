//
// FKEmptyStateDemoSupport.swift
//
// Shared builders and helpers for FKEmptyState example screens.
//

import FKUIKit
import UIKit

// MARK: - Demo factory

enum FKEmptyStateDemoFactory {
  /// Applies a global template so all demos share a consistent baseline style.
  static func configureGlobalStyleIfNeeded() {
    FKEmptyStateManager.shared.configureTemplate { model in
      model.backgroundColor = .systemBackground
      model.titleColor = .label
      model.descriptionColor = .secondaryLabel
      model.titleFont = .systemFont(ofSize: 20, weight: .semibold)
      model.descriptionFont = .systemFont(ofSize: 15, weight: .regular)
      model.verticalSpacing = 12
      model.contentInsets = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
      model.buttonStyle = FKEmptyStateButtonStyle(
        title: nil,
        titleColor: .white,
        font: .systemFont(ofSize: 15, weight: .semibold),
        backgroundColor: .systemBlue,
        cornerRadius: 12,
        contentInsets: UIEdgeInsets(top: 11, left: 18, bottom: 11, right: 18)
      )
    }
  }

  /// Creates a no-network model with "Open Settings" action text.
  static func makeNoNetworkModel() -> FKEmptyStateModel {
    var model = FKEmptyStateModel.scenario(.noNetwork)
    model.image = UIImage(systemName: "wifi.exclamationmark")
    model.buttonStyle.title = "Open Settings"
    model.isButtonHidden = false
    return model
  }

  /// Creates a retry-focused load failure model.
  static func makeLoadFailedModel() -> FKEmptyStateModel {
    var model = FKEmptyStateModel.scenario(.loadFailed)
    model.image = UIImage(systemName: "exclamationmark.arrow.trianglehead.clockwise")
    model.buttonStyle.title = "Retry"
    model.isButtonHidden = false
    return model
  }

  /// Creates an empty-data model with custom copy and icon.
  static func makeCustomEmptyModel() -> FKEmptyStateModel {
    var model = FKEmptyStateModel(
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

  /// Creates a custom business-state model for service maintenance.
  static func makeMaintenanceModel() -> FKEmptyStateModel {
    var model = FKEmptyStateModel.customState(
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
}

// MARK: - UIKit helpers

extension UIViewController {
  /// Presents a compact alert used by examples to show callback results.
  func fk_presentMessageAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
