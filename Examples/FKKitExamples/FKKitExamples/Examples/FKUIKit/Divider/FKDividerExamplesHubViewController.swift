import UIKit

/// Entry table for focused FKDivider demos.
final class FKDividerExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: "Basics & layout",
      subtitle: "Horizontal, vertical, hairline, insets, thickness, color",
      controllerType: FKDividerExampleBasicsViewController.self
    ),
    Row(
      title: "Line styles & gradients",
      subtitle: "Solid, dashed patterns, gradient strokes",
      controllerType: FKDividerExampleLineStyleViewController.self
    ),
    Row(
      title: "Edges & defaults",
      subtitle: "Pinned edges, global defaults, Interface Builder",
      controllerType: FKDividerExampleLayoutViewController.self
    ),
    Row(
      title: "Adaptive UI",
      subtitle: "Dark mode and rotation",
      controllerType: FKDividerExampleAdaptiveViewController.self
    ),
    Row(
      title: "SwiftUI",
      subtitle: "FKDividerView in a hosting controller",
      controllerType: FKDividerExampleSwiftUIViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKDivider"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var cfg = cell.defaultContentConfiguration()
    cfg.text = row.title
    cfg.secondaryText = row.subtitle
    cfg.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = cfg
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
