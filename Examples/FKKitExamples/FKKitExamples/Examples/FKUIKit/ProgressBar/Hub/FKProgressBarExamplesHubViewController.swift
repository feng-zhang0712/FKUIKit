import FKUIKit
import UIKit

/// Lists ``FKProgressBar`` example screens.
final class FKProgressBarExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "Interactive", items: [
      DemoItem(
        title: "Playground (full configuration)",
        subtitle: "All public knobs on one live bar.",
        factory: { FKProgressBarPlaygroundDemoViewController() }
      ),
      DemoItem(
        title: "Progress as button",
        subtitle: "UIControl actions, custom titles, touch target and haptics.",
        factory: { FKProgressBarProgressButtonDemoViewController() }
      ),
      DemoItem(
        title: "Preset gallery",
        subtitle: "Side-by-side product-style presets.",
        factory: { FKProgressBarGalleryDemoViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "Delegate event log",
        subtitle: "Delegate callbacks with timestamps.",
        factory: { FKProgressBarDelegateLogDemoViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "`FKProgressBarView` and bindings.",
        factory: { FKProgressBarSwiftUIDemoViewController() }
      ),
    ]),
    DemoSection(title: "Layout & accessibility", items: [
      DemoItem(
        title: "RTL, semantics & VoiceOver copy",
        subtitle: "Forced RTL and custom accessibility strings.",
        factory: { FKProgressBarEnvironmentDemoViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKProgressBar"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = sections[indexPath.section].items[indexPath.row].factory()
    navigationController?.pushViewController(vc, animated: true)
  }
}
