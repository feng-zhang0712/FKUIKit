import UIKit

/// Table of links into focused FKBadge demo screens.
final class FKBadgeExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: "Basics & numbers",
      subtitle: "Appearance, dot, counts, text",
      controllerType: FKBadgeExampleBasicsViewController.self
    ),
    Row(
      title: "Anchors & layout",
      subtitle: "Corners, grid, offset slider",
      controllerType: FKBadgeExampleAnchorsViewController.self
    ),
    Row(
      title: "Appearance & behavior",
      subtitle: "Styling, visibility, animations, parsing",
      controllerType: FKBadgeExampleAppearanceViewController.self
    ),
    Row(
      title: "System integration",
      subtitle: "Tab bar item, bar button pattern, RTL",
      controllerType: FKBadgeExampleIntegrationViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBadge"
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
    let row = rows[indexPath.row]
    let vc = row.controllerType.init(nibName: nil, bundle: nil)
    vc.title = row.title
    navigationController?.pushViewController(vc, animated: true)
  }
}
