//
// FKEmptyStateExamplesHubViewController.swift
//
// Root menu for copy-ready FKEmptyState integration examples.
//

import UIKit

// MARK: - Hub

/// Entry list for FKEmptyState examples grouped by host view type.
final class FKEmptyStateExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case uiView
    case tableView
    case collectionView
    case businessState

    var title: String {
      switch self {
      case .uiView: return "UIView Example"
      case .tableView: return "UITableView Example"
      case .collectionView: return "UICollectionView Example"
      case .businessState: return "Custom Business State Example"
      }
    }

    var subtitle: String {
      switch self {
      case .uiView:
        return "Manual show/hide + loading/failed/no-network on a normal UIView"
      case .tableView:
        return "Auto hide after data loaded + retry/refresh callbacks"
      case .collectionView:
        return "Empty state integration for collection layouts"
      case .businessState:
        return "Global style + custom phase + network setting callback"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    FKEmptyStateDemoFactory.configureGlobalStyleIfNeeded()
    title = "FKEmptyState"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Row.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = Row.allCases[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let destination: UIViewController
    switch Row.allCases[indexPath.row] {
    case .uiView:
      destination = FKEmptyStateUIViewExampleViewController()
    case .tableView:
      destination = FKEmptyStateTableViewExampleViewController()
    case .collectionView:
      destination = FKEmptyStateCollectionViewExampleViewController()
    case .businessState:
      destination = FKEmptyStateBusinessStateExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
