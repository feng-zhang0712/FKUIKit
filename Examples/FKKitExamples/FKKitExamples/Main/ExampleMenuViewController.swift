//
//  ExampleMenuViewController.swift
//  FKKitExamples
//

import UIKit
import FKBusinessKit

/// Example entry list: navigates to view controllers under `Examples/`.
final class ExampleMenuViewController: UITableViewController {

  private struct MenuItem {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let menuItems: [MenuItem] = [
    MenuItem(
      title: "FKButton",
      subtitle: "Split demos: basics, layout, interaction, appearance, loading",
      make: { FKButtonExamplesHubViewController() }
    ),
    MenuItem(
      title: "FKBar",
      subtitle: "Horizontal item bar with selection callbacks",
      make: { FKBarExampleViewController() }
    ),
    MenuItem(
      title: "FKPresentation",
      subtitle: "Anchored panel with mask",
      make: { FKPresentationExampleViewController() }
    ),
    MenuItem(
      title: "FKBarPresentation",
      subtitle: "Bar + anchored panel composite",
      make: { FKBarPresentationExampleViewController() }
    ),
    MenuItem(
      title: "Filter",
      subtitle: "Business-like dropdown filters (top bar + panels)",
      make: { FKFilterExampleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKUIKit Example"
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
