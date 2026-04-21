//
// FKStickyExamplesHubViewController.swift
//

import UIKit

/// Entry list for FKSticky examples.
final class FKStickyExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case comprehensive
    case tableView
    case collectionView

    var title: String {
      switch self {
      case .comprehensive:
        return "Comprehensive API Playground"
      case .tableView:
        return "UITableView Group Header Sticky"
      case .collectionView:
        return "UICollectionView Section Sticky"
      }
    }

    var subtitle: String {
      switch self {
      case .comprehensive:
        return "Multi-target chain sticky, style switch, callbacks, and runtime toggles"
      case .tableView:
        return "Section headers with smooth sticky transitions and offset adaptation"
      case .collectionView:
        return "Collection section headers with sticky coordination"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSticky"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
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
    case .comprehensive:
      destination = FKStickyComprehensiveExampleViewController()
    case .tableView:
      destination = FKStickyTableExampleViewController()
    case .collectionView:
      destination = FKStickyCollectionExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
