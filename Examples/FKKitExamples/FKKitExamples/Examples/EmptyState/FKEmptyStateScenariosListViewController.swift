//
// FKEmptyStateScenariosListViewController.swift
//
// Lists every `FKEmptyStateScenario` case; pushes a full-screen preview for the selection.
//

import FKUIKit
import UIKit

// MARK: - Scenarios list

/// Master list of `FKEmptyStateScenario.allCases` for quick visual inspection.
final class FKEmptyStateScenariosListViewController: UITableViewController {

  // MARK: Properties

  private let scenarios = FKEmptyStateScenario.allCases

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scenarios"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  // MARK: UITableViewDataSource

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    scenarios.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let scenario = scenarios[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = scenario.demoDisplayName
    config.secondaryText = String(describing: scenario)
    config.secondaryTextProperties.font = .preferredFont(forTextStyle: .caption1)
    config.secondaryTextProperties.color = .tertiaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  // MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let scenario = scenarios[indexPath.row]
    navigationController?.pushViewController(
      FKEmptyStateScenarioPreviewViewController(scenario: scenario),
      animated: true
    )
  }
}
