//
// FKCornerShadowExamplesHubViewController.swift
//
// Root menu for FKCornerShadow copy-ready examples.
//

import UIKit

/// Entry list for FKCornerShadow examples.
final class FKCornerShadowExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "UIView Core Scenarios",
      subtitle: "Any-corner radius, shadow path, gradients, auto frame update, and reset",
      make: { FKCornerShadowUIViewExampleViewController() }
    ),
    Row(
      title: "UIKit Controls",
      subtitle: "UIButton/UILabel/UIImageView styling with one-line APIs",
      make: { FKCornerShadowControlsExampleViewController() }
    ),
    Row(
      title: "Table & Collection Reuse",
      subtitle: "UITableViewCell/UICollectionViewCell performance and reuse-safe reset",
      make: { FKCornerShadowListExampleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    FKCornerShadowDemoSupport.configureGlobalStyleIfNeeded()
    title = "FKCornerShadow"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
