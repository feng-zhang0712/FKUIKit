//
//  DemoMenuViewController.swift
//  FKUIKitDemo
//

import UIKit

/// Demo entry list: navigates to view controllers under `Demos/`.
final class DemoMenuViewController: UITableViewController {

  private struct MenuItem {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let menuItems: [MenuItem] = [
    MenuItem(
      title: "FKButton",
      subtitle: "Title, image, subtitle, and appearance variants",
      make: { FKButtonDemoViewController() }
    ),
    MenuItem(
      title: "FKBar",
      subtitle: "Horizontal item bar with selection callbacks",
      make: { FKBarDemoViewController() }
    ),
    MenuItem(
      title: "FKPresentation",
      subtitle: "Anchored panel with mask",
      make: { FKPresentationDemoViewController() }
    ),
    MenuItem(
      title: "FKBarPresentation",
      subtitle: "Bar + anchored panel composite",
      make: { FKBarPresentationDemoViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKUIKit Demo"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    menuItems.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = menuItems[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = menuItems[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
