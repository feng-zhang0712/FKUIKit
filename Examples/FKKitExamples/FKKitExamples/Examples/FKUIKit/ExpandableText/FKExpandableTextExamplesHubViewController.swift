//
// FKExpandableTextExamplesHubViewController.swift
//
// Root menu for copy-ready FKExpandableText integration examples.
//

import UIKit

/// Entry list for FKExpandableText examples.
final class FKExpandableTextExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case basic
    case tableView
    case collectionView

    var title: String {
      switch self {
      case .basic:
        return "Basic Features Playground"
      case .tableView:
        return "UITableView Reuse + State Cache"
      case .collectionView:
        return "UICollectionView Adaptation"
      }
    }

    var subtitle: String {
      switch self {
      case .basic:
        return "Text style, attributed text, custom button, animation, callback, manual control"
      case .tableView:
        return "High-volume list reuse with stable identifiers and dynamic height updates"
      case .collectionView:
        return "Card-style collection with expandable content and reuse-safe state restoration"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKExpandableText"
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
    case .basic:
      destination = FKExpandableTextBasicExampleViewController()
    case .tableView:
      destination = FKExpandableTextTableExampleViewController()
    case .collectionView:
      destination = FKExpandableTextCollectionExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
