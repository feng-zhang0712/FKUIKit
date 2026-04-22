import UIKit

/// Entry list for FKSwipeAction demos (UIKit).
///
/// - Goals:
///   - Clear structure: one hub + per-scenario pages
///   - Minimal code: keep only the core integration calls
///   - Copy-ready: examples are designed to be copied into real projects
final class FKSwipeActionExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "Basics: UITableView (Single Action)",
      subtitle: "One-line enablement + one right action",
      make: { FKSwipeActionTableScenarioViewController(mode: .tableSingleButton) }
    ),
    Row(
      title: "UITableView (Multiple Actions)",
      subtitle: "Multiple right actions: delete / pin / mark",
      make: { FKSwipeActionTableScenarioViewController(mode: .tableMultiButtons) }
    ),
    Row(
      title: "UICollectionView Support",
      subtitle: "One-line enablement + multiple actions",
      make: { FKSwipeActionCollectionScenarioViewController() }
    ),
    Row(
      title: "Right Swipe (Left Actions)",
      subtitle: "Swipe right to reveal left actions",
      make: { FKSwipeActionTableScenarioViewController(mode: .rightSwipe) }
    ),

    Row(
      title: "Button Style: Text Only",
      subtitle: "layout = .title",
      make: { FKSwipeActionTableScenarioViewController(mode: .textOnly) }
    ),
    Row(
      title: "Button Style: Icon Only",
      subtitle: "layout = .icon",
      make: { FKSwipeActionTableScenarioViewController(mode: .iconOnly) }
    ),
    Row(
      title: "Button Style: Icon + Title (Vertical)",
      subtitle: "layout = .iconTop",
      make: { FKSwipeActionTableScenarioViewController(mode: .iconTop) }
    ),
    Row(
      title: "Button Style: Icon + Title (Horizontal)",
      subtitle: "layout = .iconLeading",
      make: { FKSwipeActionTableScenarioViewController(mode: .iconLeading) }
    ),
    Row(
      title: "Button Style: Gradient Background",
      subtitle: "vertical/horizontal gradient",
      make: { FKSwipeActionTableScenarioViewController(mode: .gradientBackground) }
    ),
    Row(
      title: "Button Style: Custom Color / Font / Corner",
      subtitle: "font/titleColor/cornerRadius/width",
      make: { FKSwipeActionTableScenarioViewController(mode: .customStyle) }
    ),

    Row(
      title: "Mutual Exclusion (Single Open)",
      subtitle: "allowsOnlyOneOpen = true (default)",
      make: { FKSwipeActionTableScenarioViewController(mode: .exclusiveOpen) }
    ),
    Row(
      title: "Allow Multiple Open Cells",
      subtitle: "allowsOnlyOneOpen = false",
      make: { FKSwipeActionTableScenarioViewController(mode: .multipleOpen) }
    ),
    Row(
      title: "Tap to Close",
      subtitle: "tapToClose = true (default)",
      make: { FKSwipeActionTableScenarioViewController(mode: .tapToClose) }
    ),
    Row(
      title: "Custom Open Threshold",
      subtitle: "openThreshold = 120 (harder to open)",
      make: { FKSwipeActionTableScenarioViewController(mode: .customThreshold) }
    ),
    Row(
      title: "State Callback",
      subtitle: "Observe begin/end/tap via onEvent",
      make: { FKSwipeActionTableScenarioViewController(mode: .stateCallback) }
    ),
    Row(
      title: "Dynamic Enable / Disable",
      subtitle: "fk_setSwipeActionsEnabled(true/false)",
      make: { FKSwipeActionTableScenarioViewController(mode: .dynamicToggle) }
    ),
    Row(
      title: "Global Defaults",
      subtitle: "FKSwipeActionManager.globalDefaultConfiguration",
      make: { FKSwipeActionGlobalConfigDemoViewController() }
    ),
    Row(
      title: "SwiftUI Support",
      subtitle: "List + .fk_swipeAction(...)",
      make: { FKSwipeActionSwiftUIHostViewController() }
    ),
    Row(
      title: "Dark Mode",
      subtitle: "overrideUserInterfaceStyle = .dark",
      make: { FKSwipeActionTableScenarioViewController(mode: .darkMode) }
    ),
    Row(
      title: "Rotation",
      subtitle: "Portrait/landscape adaptation",
      make: { FKSwipeActionTableScenarioViewController(mode: .rotation) }
    ),
    Row(
      title: "Performance Test (FPS)",
      subtitle: "Large dataset + FPS meter",
      make: { FKSwipeActionPerformanceDemoViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSwipeAction"
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

