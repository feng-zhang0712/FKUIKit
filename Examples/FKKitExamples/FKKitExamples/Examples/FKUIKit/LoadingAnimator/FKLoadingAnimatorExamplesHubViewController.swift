//
// FKLoadingAnimatorExamplesHubViewController.swift
//
// Root menu for FKLoadingAnimator examples.
//

import UIKit

/// Entry list for FKLoadingAnimator examples.
final class FKLoadingAnimatorExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case comprehensive
    case tableView
    case collectionView

    var title: String {
      switch self {
      case .comprehensive:
        return "Comprehensive API Playground"
      case .tableView:
        return "UITableView Cell Adaptation"
      case .collectionView:
        return "UICollectionView Cell Adaptation"
      }
    }

    var subtitle: String {
      switch self {
      case .comprehensive:
        return "Fullscreen, embedded, style switch, progress, callbacks, global config"
      case .tableView:
        return "Safe loading states in reusable table cells"
      case .collectionView:
        return "Safe loading states in reusable collection cells"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKLoadingAnimator"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    FKLoadingAnimatorDemoFactory.configureGlobalStyleIfNeeded()
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
      destination = FKLoadingAnimatorComprehensiveExampleViewController()
    case .tableView:
      destination = FKLoadingAnimatorTableExampleViewController()
    case .collectionView:
      destination = FKLoadingAnimatorCollectionExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}

