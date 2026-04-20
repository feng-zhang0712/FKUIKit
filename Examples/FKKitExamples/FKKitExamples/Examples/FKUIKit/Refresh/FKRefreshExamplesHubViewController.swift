//
// FKRefreshExamplesHubViewController.swift
// FKKitExamples — FKRefresh demos
//
// Hub table: navigates to each demo screen (default, custom, GIF, delegate, settings, etc.).
//

import FKUIKit
import UIKit

/// Lists every demo that exercises a distinct public type or integration path.
final class FKRefreshExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case defaultIndicator
    case customDots
    case gif
    case hosted
    case configuration
    case globalSettings
    case delegate
    case pagination
    case collectionView
    case plainScrollView

    var title: String {
      switch self {
      case .defaultIndicator: return "Default indicator"
      case .customDots: return "Custom dots (FKRefreshContentView)"
      case .gif: return "GIF (FKGIFRefreshContentView)"
      case .hosted: return "Hosted view (FKHostedRefreshContentView)"
      case .configuration: return "Configuration & silent refresh"
      case .globalSettings: return "Global defaults (FKRefreshSettings)"
      case .delegate: return "Delegate (FKRefreshControlDelegate)"
      case .pagination: return "Pagination helper (FKRefreshPagination)"
      case .collectionView: return "UICollectionView"
      case .plainScrollView: return "Plain UIScrollView"
      }
    }

    var subtitle: String {
      switch self {
      case .defaultIndicator:
        return "FKDefaultRefreshContentView — pull + load more, triggers"
      case .customDots:
        return "Custom UIView conforming to FKRefreshContentView"
      case .gif:
        return "UIImage animatedImage in FKGIFRefreshContentView"
      case .hosted:
        return "Arbitrary UIView subtree (Lottie-style hosting)"
      case .configuration:
        return "FKRefreshText, silent, min loading visibility"
      case .globalSettings:
        return "FKRefreshSettings.pullToRefresh / loadMore"
      case .delegate:
        return "Protocol callbacks vs onStateChanged"
      case .pagination:
        return "FKRefreshPagination with page label"
      case .collectionView:
        return "Same APIs on UICollectionView"
      case .plainScrollView:
        return "Not UITableView — vertical UIScrollView"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRefresh"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

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

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc: UIViewController
    switch Row.allCases[indexPath.row] {
    case .defaultIndicator:
      vc = FKRefreshDefaultDemoViewController()
    case .customDots:
      vc = FKRefreshDotsDemoViewController()
    case .gif:
      vc = FKRefreshGIFDemoViewController()
    case .hosted:
      vc = FKRefreshHostedDemoViewController()
    case .configuration:
      vc = FKRefreshConfigurationDemoViewController()
    case .globalSettings:
      vc = FKRefreshGlobalSettingsDemoViewController()
    case .delegate:
      vc = FKRefreshDelegateDemoViewController()
    case .pagination:
      vc = FKRefreshPaginationDemoViewController()
    case .collectionView:
      vc = FKRefreshCollectionDemoViewController()
    case .plainScrollView:
      vc = FKRefreshScrollViewDemoViewController()
    }
    navigationController?.pushViewController(vc, animated: true)
  }
}
