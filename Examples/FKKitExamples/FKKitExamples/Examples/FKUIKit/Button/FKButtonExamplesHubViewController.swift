import UIKit

/// Entry table for FKButton example screens (see `Scenarios/`).
final class FKButtonExamplesHubViewController: UITableViewController {

  private struct Row {
    let title: String
    let subtitle: String
    let controllerType: UIViewController.Type
  }

  private let rows: [Row] = [
    Row(
      title: "Basics",
      subtitle: "Text only, icon only, text + image composition",
      controllerType: FKButtonExampleBasicsViewController.self
    ),
    Row(
      title: "Layout & content",
      subtitle: "Axis, capsule, subtitles, content kind morphing",
      controllerType: FKButtonExampleLayoutViewController.self
    ),
    Row(
      title: "Interaction",
      subtitle: "Tap interval, hit target, long press, haptics/sound, chaining",
      controllerType: FKButtonExampleInteractionViewController.self
    ),
    Row(
      title: "Appearance",
      subtitle: "Gradient, highlight feedback, disabled dimming, spacing",
      controllerType: FKButtonExampleAppearanceViewController.self
    ),
    Row(
      title: "Loading",
      subtitle: "Overlay vs hidden-content + status text, async guard",
      controllerType: FKButtonExampleLoadingViewController.self
    ),
    Row(
      title: "Global & Interface Builder",
      subtitle: "GlobalStyle snapshot, Storyboard inspectables",
      controllerType: FKButtonExampleAdvancedViewController.self
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKButton"
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
