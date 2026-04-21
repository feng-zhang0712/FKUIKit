//
// FKCarouselExamplesHubViewController.swift
//
// Root menu for FKCarousel examples.
//

import UIKit

/// Entry list for FKCarousel examples.
final class FKCarouselExamplesHubViewController: UITableViewController {
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
        return "Infinite loop, callbacks, style, auto scroll, dynamic update, and more"
      case .tableView:
        return "Reusable table cell integration with smooth paging"
      case .collectionView:
        return "Reusable collection cell integration with smooth paging"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKCarousel"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    FKCarouselDemoSupport.configureGlobalStyleIfNeeded()
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
      destination = FKCarouselComprehensiveExampleViewController()
    case .tableView:
      destination = FKCarouselTableExampleViewController()
    case .collectionView:
      destination = FKCarouselCollectionExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
