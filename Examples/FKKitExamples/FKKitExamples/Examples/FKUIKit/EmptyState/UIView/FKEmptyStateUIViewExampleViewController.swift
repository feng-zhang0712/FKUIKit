//
// FKEmptyStateUIViewExampleViewController.swift
//
// Copy-ready example for integrating FKEmptyState with a normal UIView host.
//

import FKUIKit
import UIKit

/// Demonstrates one-line show/hide, load failure, no network, and custom UI on UIView.
final class FKEmptyStateUIViewExampleViewController: UIViewController {
  private let contentHostView = UIView()
  private let segmented = UISegmentedControl(items: ["Empty", "Failed", "No Network", "Hide"])
  private let applyCustomButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UIView Empty State"
    view.backgroundColor = .systemBackground
    buildUI()
    showCustomEmptyState()
  }

  private func buildUI() {
    contentHostView.translatesAutoresizingMaskIntoConstraints = false
    contentHostView.backgroundColor = .secondarySystemBackground
    contentHostView.layer.cornerRadius = 14
    view.addSubview(contentHostView)

    segmented.translatesAutoresizingMaskIntoConstraints = false
    segmented.selectedSegmentIndex = 0
    segmented.addTarget(self, action: #selector(segmentedChanged), for: .valueChanged)
    view.addSubview(segmented)

    applyCustomButton.translatesAutoresizingMaskIntoConstraints = false
    applyCustomButton.setTitle("Apply Custom UI Style", for: .normal)
    applyCustomButton.addTarget(self, action: #selector(customButtonTapped), for: .touchUpInside)
    view.addSubview(applyCustomButton)

    NSLayoutConstraint.activate([
      segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      applyCustomButton.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
      applyCustomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      contentHostView.topAnchor.constraint(equalTo: applyCustomButton.bottomAnchor, constant: 16),
      contentHostView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      contentHostView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      contentHostView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])
  }

  @objc private func segmentedChanged() {
    switch segmented.selectedSegmentIndex {
    case 1:
      showLoadFailed()
    case 2:
      showNoNetwork()
    case 3:
      contentHostView.fk_hideEmptyState()
    default:
      showCustomEmptyState()
    }
  }

  @objc private func customButtonTapped() {
    showCustomEmptyState()
  }

  /// Shows a fully customized empty state on a regular UIView.
  private func showCustomEmptyState() {
    var model = FKEmptyStateDemoFactory.makeCustomEmptyModel()
    model.contentInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    model.titleFont = .systemFont(ofSize: 22, weight: .bold)
    model.descriptionFont = .systemFont(ofSize: 14, weight: .medium)
    model.maxContentWidth = 320
    model.verticalOffset = -20

    contentHostView.fk_applyEmptyState(model, actionHandler: { [weak self] in
      self?.fk_presentMessageAlert(title: "Create", message: "Create button tapped.")
    })
  }

  /// Shows load failure with retry callback.
  private func showLoadFailed() {
    let model = FKEmptyStateDemoFactory.makeLoadFailedModel()
    contentHostView.fk_applyEmptyState(model, actionHandler: { [weak self] in
      self?.fk_presentMessageAlert(title: "Retry", message: "Retry tapped for UIView host.")
    })
  }

  /// Shows no-network state with open-settings callback.
  private func showNoNetwork() {
    let model = FKEmptyStateDemoFactory.makeNoNetworkModel()
    contentHostView.fk_applyEmptyState(model, actionHandler: {
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    })
  }
}
