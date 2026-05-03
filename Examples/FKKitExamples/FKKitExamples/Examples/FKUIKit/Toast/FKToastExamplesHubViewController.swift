import UIKit

final class FKToastExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "Basic Toast",
      subtitle: "Position, multiline text, style, icon, custom view",
      make: { FKToastBasicsExampleViewController() }
    ),
    Row(
      title: "Queue & Strategy",
      subtitle: "Burst queue, dedupe/coalesce, priority interruption",
      make: { FKToastQueueStrategyExampleViewController() }
    ),
    Row(
      title: "HUD",
      subtitle: "Loading, progress, success/failure, blocking and timeout",
      make: { FKToastHUDExampleViewController() }
    ),
    Row(
      title: "Snackbar",
      subtitle: "Actions, swipe dismiss, VoiceOver and announcement",
      make: { FKToastSnackbarExampleViewController() }
    ),
    Row(
      title: "Environment",
      subtitle: "Light/Dark, Dynamic Type, rotation, keyboard avoidance",
      make: { FKToastEnvironmentExampleViewController() }
    ),
    Row(
      title: "SwiftUI Bridge",
      subtitle: "SwiftUI trigger surface with shared UIKit implementation",
      make: { FKToastSwiftUIHostViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKToast"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

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
