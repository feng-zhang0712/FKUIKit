//
// FKSwipeActionExamplesHubViewController.swift
//
// Root menu for copy-ready FKSwipeAction integration examples.
//

import UIKit

/// Entry list for FKSwipeAction examples grouped by host list type.
final class FKSwipeActionExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case tableView
    case collectionView

    var title: String {
      switch self {
      case .tableView:
        return "UITableView Multi-Buttons (Right Swipe)"
      case .collectionView:
        return "UICollectionView Multi-Buttons (Left Swipe)"
      }
    }

    var subtitle: String {
      switch self {
      case .tableView:
        return "Text/image/mixed buttons, delete confirmation, per-cell disable, global style"
      case .collectionView:
        return "Left swipe buttons, adaptive/fixed width, smooth animation, reusable state updates"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSwipeAction"
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
    case .tableView:
      destination = FKSwipeActionTableExampleViewController()
    case .collectionView:
      destination = FKSwipeActionCollectionExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
