//
// FKBaseExamplesHubViewController.swift
//

import UIKit

/// Entry list for FKCompositeKit base module demos.
final class FKBaseExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case baseViewController

    var title: String {
      switch self {
      case .baseViewController:
        return "FKBaseViewController"
      }
    }

    var subtitle: String {
      switch self {
      case .baseViewController:
        return "Lifecycle, loading/empty/error/toast, keyboard, navigation style"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Base"
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
    case .baseViewController:
      destination = FKBaseViewControllerExampleViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
