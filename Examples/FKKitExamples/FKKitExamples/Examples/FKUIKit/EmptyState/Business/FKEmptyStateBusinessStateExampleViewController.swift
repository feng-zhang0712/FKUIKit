//
// FKEmptyStateBusinessStateExampleViewController.swift
//
// Demonstrates custom business states and global style based one-line API.
//

import FKUIKit
import UIKit

/// Demonstrates a custom business state and global-style-driven one-line rendering.
final class FKEmptyStateBusinessStateExampleViewController: UIViewController {
  private let infoLabel = UILabel()
  private let container = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Business State"
    view.backgroundColor = .systemBackground
    setupViews()
    applyMaintenanceState()
  }

  private func setupViews() {
    infoLabel.translatesAutoresizingMaskIntoConstraints = false
    infoLabel.text = "This screen uses `FKEmptyStatePhase.custom` and global style defaults."
    infoLabel.font = .systemFont(ofSize: 14)
    infoLabel.textColor = .secondaryLabel
    infoLabel.numberOfLines = 0
    view.addSubview(infoLabel)

    container.translatesAutoresizingMaskIntoConstraints = false
    container.backgroundColor = .secondarySystemGroupedBackground
    container.layer.cornerRadius = 12
    view.addSubview(container)

    let barItems = [
      UIBarButtonItem(title: "Maintenance", style: .plain, target: self, action: #selector(applyMaintenanceState)),
      UIBarButtonItem(title: "No Network", style: .plain, target: self, action: #selector(applyNoNetworkState)),
      UIBarButtonItem(title: "Hide", style: .plain, target: self, action: #selector(hideState)),
    ]
    navigationItem.rightBarButtonItems = barItems

    NSLayoutConstraint.activate([
      infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      container.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 12),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])
  }

  /// Applies a custom business state model with one-line rendering.
  @objc private func applyMaintenanceState() {
    let model = FKEmptyStateDemoFactory.makeMaintenanceModel()
    container.fk_applyEmptyState(model, actionHandler: { [weak self] in
      self?.fk_presentMessageAlert(title: "Status", message: "Maintenance status refreshed.")
    })
  }

  /// Applies no-network state and opens app settings when the button is tapped.
  @objc private func applyNoNetworkState() {
    container.fk_setEmptyState(animated: true, actionHandler: {
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    }) { model in
      model = FKEmptyStateDemoFactory.makeNoNetworkModel()
      model.contentAlignment = .top
      model.verticalOffset = 24
      model.titleColor = .systemRed
      model.buttonStyle.backgroundColor = .systemRed
    }
  }

  /// Hides the placeholder manually.
  @objc private func hideState() {
    container.fk_hideEmptyState(animated: true)
  }
}
