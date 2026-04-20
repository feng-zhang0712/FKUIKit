//
// FKStarRatingExamplesHubViewController.swift
//
// Root menu for FKStarRating examples.
//

import UIKit

/// Entry list for FKStarRating examples.
final class FKStarRatingExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case basic
    case tableView

    var title: String {
      switch self {
      case .basic:
        return "Basic Features Playground"
      case .tableView:
        return "UITableView Reuse Adaptation"
      }
    }

    var subtitle: String {
      switch self {
      case .basic:
        return "Full, half, precise, read-only, styles, callbacks, global config, reset"
      case .tableView:
        return "Interactive rating in reusable cells without callback/state disorder"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKStarRating"
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
      destination = FKStarRatingBasicExampleViewController()
    case .tableView:
      destination = FKStarRatingTableExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
