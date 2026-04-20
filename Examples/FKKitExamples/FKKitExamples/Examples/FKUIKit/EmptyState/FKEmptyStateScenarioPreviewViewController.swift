//
// FKEmptyStateScenarioPreviewViewController.swift
//
// Single-scenario preview: zero rows + `fk_applyEmptyState` with opaque background.
//

import FKUIKit
import UIKit

// MARK: - Preview

/// Shows one `FKEmptyStateScenario` on an otherwise empty `UITableView`.
final class FKEmptyStateScenarioPreviewViewController: UIViewController {

  // MARK: Properties

  private let scenario: FKEmptyStateScenario

  private lazy var tableView: UITableView = {
    let t = UITableView(frame: .zero, style: .insetGrouped)
    t.translatesAutoresizingMaskIntoConstraints = false
    t.dataSource = self
    t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    return t
  }()

  // MARK: Lifecycle

  init(scenario: FKEmptyStateScenario) {
    self.scenario = scenario
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    title = scenario.demoDisplayName

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    applyEmptyState()
  }

  // MARK: Empty state

  private func applyEmptyState() {
    var model = FKEmptyStateModel.scenario(scenario)
      .withImage(UIImage(systemName: scenario.demoSymbolName))
    model.backgroundColor = .systemBackground
    model.supportsTapToDismissKeyboard = true
    tableView.fk_applyEmptyState(model, animated: false, actionHandler: { [weak self] in
      self?.showRetryHint()
    })
  }

  private func showRetryHint() {
    let alert = UIAlertController(
      title: "Action",
      message: "Primary button tapped (reload / retry / etc. per scenario).",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - UITableViewDataSource

extension FKEmptyStateScenarioPreviewViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
  }
}
