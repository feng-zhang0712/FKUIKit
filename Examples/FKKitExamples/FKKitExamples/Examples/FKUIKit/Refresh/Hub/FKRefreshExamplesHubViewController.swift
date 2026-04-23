import FKUIKit
import UIKit

/// Lists every demo that exercises a distinct public type or integration path.
final class FKRefreshExamplesHubViewController: UITableViewController {
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
    DemoSection(title: "Foundations", items: [
      DemoItem(
        title: "UITableView baseline",
        subtitle: "Goal: pull gesture + programmatic trigger. Params: default config. Expect: success/error/empty/cancel safe transitions.",
        factory: { FKRefreshDefaultDemoViewController() }
      ),
      DemoItem(
        title: "UICollectionView baseline",
        subtitle: "Goal: verify same API on collection lists. Params: segmented outcomes. Expect: paged loading and retry-ready failure state.",
        factory: { FKRefreshCollectionDemoViewController() }
      ),
      DemoItem(
        title: "UIScrollView generic",
        subtitle: "Goal: non-list scroll integration. Params: manual footer mode. Expect: stable header/footer layout on plain scroll content.",
        factory: { FKRefreshScrollViewDemoViewController() }
      ),
      DemoItem(
        title: "Async/Await flow",
        subtitle: "Goal: async handlers + auto end. Params: automaticEndDelay. Expect: no duplicate triggers while requests run.",
        factory: { FKRefreshAsyncAwaitExampleViewController() }
      ),
    ]),
    DemoSection(title: "Customization", items: [
      DemoItem(
        title: "Configuration + silent mode",
        subtitle: "Goal: text/theme/timing knobs. Params: minimum visibility + silent refresh. Expect: no loading flash and configurable copy.",
        factory: { FKRefreshConfigurationDemoViewController() }
      ),
      DemoItem(
        title: "Custom dots view",
        subtitle: "Goal: custom indicator animation. Params: FKRefreshContentView protocol. Expect: progress-driven visuals stay in sync.",
        factory: { FKRefreshDotsDemoViewController() }
      ),
      DemoItem(
        title: "GIF indicator",
        subtitle: "Goal: animated-image indicator. Params: FKGIFRefreshContentView. Expect: animation starts/stops by state.",
        factory: { FKRefreshGIFDemoViewController() }
      ),
      DemoItem(
        title: "Hosted view adapter",
        subtitle: "Goal: host arbitrary UIKit subtree. Params: FKHostedRefreshContentView. Expect: custom view follows state transitions.",
        factory: { FKRefreshHostedDemoViewController() }
      ),
    ]),
    DemoSection(title: "Concurrency + Boundaries", items: [
      DemoItem(
        title: "Policy and stress test",
        subtitle: "Goal: conflict policy + rapid gestures. Params: mutex/queue/parallel + autoFill. Expect: no duplicate in-flight actions.",
        factory: { FKRefreshPolicyStressExampleViewController() }
      ),
      DemoItem(
        title: "Delegate logging",
        subtitle: "Goal: inspect exact state graph. Params: delegate + closure observers. Expect: deterministic transitions for QA logs.",
        factory: { FKRefreshDelegateDemoViewController() }
      ),
      DemoItem(
        title: "Pagination helper",
        subtitle: "Goal: page1→pageN lifecycle. Params: FKRefreshPagination reset/advance. Expect: noMoreData and reset recovery.",
        factory: { FKRefreshPaginationDemoViewController() }
      ),
    ]),
    DemoSection(title: "Global + Environment", items: [
      DemoItem(
        title: "Global defaults",
        subtitle: "Goal: shared style baseline. Params: FKRefreshSettings + manager updates. Expect: screens inherit defaults consistently.",
        factory: { FKRefreshGlobalSettingsDemoViewController() }
      ),
      DemoItem(
        title: "Complex environment suite",
        subtitle: "Goal: large title + tab bar + keyboard + rotation. Params: nested nav/tab containers. Expect: stable insets and no state drift.",
        factory: { FKRefreshComplexEnvironmentDemoViewController() }
      ),
      DemoItem(
        title: "Localization + accessibility",
        subtitle: "Goal: i18n and a11y validation. Params: English/Spanish + Dynamic Type + RTL. Expect: readable copy and VoiceOver feedback.",
        factory: { FKRefreshLocalizationAccessibilityDemoViewController() }
      ),
    ]),
    DemoSection(title: "SwiftUI Bridge", items: [
      DemoItem(
        title: "SwiftUI list via bridge",
        subtitle: "Goal: reuse UIKit refresh core in SwiftUI. Params: FKRefreshSwiftUIBridge + token-safe completion. Expect: single logic path.",
        factory: { FKRefreshSwiftUIBridgeDemoViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRefresh"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    navigationController?.navigationBar.prefersLargeTitles = false
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
