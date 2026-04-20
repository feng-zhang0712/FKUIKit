//
// FKEmptyStateExamplesHubViewController.swift
//
// Root menu: navigates to each FKEmptyState demo screen.
//

import FKUIKit
import UIKit

// MARK: - Hub

/// Table-driven entry list for all empty-state examples in FKKitExamples.
final class FKEmptyStateExamplesHubViewController: UITableViewController {

  // MARK: Types

  /// One row per demo destination.
  private enum Row: Int, CaseIterable {
    case builtInScenarios
    case phases
    case sandbox
    case retryFailure

    var title: String {
      switch self {
      case .builtInScenarios: return "Built-in scenarios"
      case .phases: return "Phases"
      case .sandbox: return "Interactive sandbox"
      case .retryFailure: return "Retry → still fails"
      }
    }

    var subtitle: String {
      switch self {
      case .builtInScenarios:
        return "All FKEmptyStateScenario presets on an empty table"
      case .phases:
        return "content / loading / empty / error"
      case .sandbox:
        return "Toggles, gradient, loading, segmented scenarios"
      case .retryFailure:
        return "Tap Retry → loading → error again after a delay"
      }
    }
  }

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKEmptyState"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  // MARK: UITableViewDataSource

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Row.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = Row.allCases[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  // MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc: UIViewController
    switch Row.allCases[indexPath.row] {
    case .builtInScenarios:
      vc = FKEmptyStateScenariosListViewController()
    case .phases:
      vc = FKEmptyStatePhasesDemoViewController()
    case .sandbox:
      vc = FKEmptyStateSandboxViewController()
    case .retryFailure:
      vc = FKEmptyStateRetryFailureDemoViewController()
    }
    navigationController?.pushViewController(vc, animated: true)
  }
}
