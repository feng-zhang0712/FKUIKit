import UIKit

/// Entry list for FKStickyHeader examples.
final class FKStickyExamplesHubViewController: UITableViewController {
  private enum Row: Int, CaseIterable {
    case tableSingle
    case tableMulti
    case collectionBasic
    case collectionWaterfall
    case customOffset
    case alphaAnimation
    case backgroundAnimation
    case scaleAnimation
    case stateCallback
    case toggleSticky
    case globalConfiguration
    case swiftUI
    case darkMode
    case rotation
    case performance

    var title: String {
      switch self {
      case .tableSingle: return "UITableView Single Section Sticky"
      case .tableMulti: return "UITableView Multi-Section Sticky"
      case .collectionBasic: return "UICollectionView Multi-Section Sticky"
      case .collectionWaterfall: return "UICollectionView Waterfall Sticky"
      case .customOffset: return "Custom Sticky Offset"
      case .alphaAnimation: return "Sticky Alpha Animation"
      case .backgroundAnimation: return "Sticky Background Animation"
      case .scaleAnimation: return "Sticky Scale Animation"
      case .stateCallback: return "Sticky State Callback"
      case .toggleSticky: return "Dynamic Sticky Toggle"
      case .globalConfiguration: return "Global Configuration"
      case .swiftUI: return "SwiftUI Sticky Demo"
      case .darkMode: return "Dark Mode Adaptation"
      case .rotation: return "Rotation Adaptation"
      case .performance: return "Performance Test (60fps)"
      }
    }

    var subtitle: String {
      switch self {
      case .tableSingle: return "Minimal copy-ready setup, enabled in one line"
      case .tableMulti: return "Contacts-style list with section push-off behavior"
      case .collectionBasic: return "Basic sticky section header setup"
      case .collectionWaterfall: return "Custom layout with sticky section headers"
      case .customOffset: return "Avoid nav bar or top overlays"
      case .alphaAnimation: return "Progress-driven alpha transition"
      case .backgroundAnimation: return "Progress-driven background color transition"
      case .scaleAnimation: return "Progress-driven scale transition"
      case .stateCallback: return "willSticky / didSticky / didUnsticky"
      case .toggleSticky: return "Enable or disable sticky behavior at runtime"
      case .globalConfiguration: return "Global defaults with per-screen override"
      case .swiftUI: return "SwiftUI integration inside a UIKit project"
      case .darkMode: return "Automatic light/dark mode compatibility"
      case .rotation: return "Auto relayout on orientation changes"
      case .performance: return "Live FPS indicator during scrolling"
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKStickyHeader Full Scenario Demo"
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
    case .tableSingle:
      destination = FKStickyTableSingleSectionViewController()
    case .tableMulti:
      destination = FKStickyTableMultiSectionViewController()
    case .collectionBasic:
      destination = FKStickyCollectionBasicViewController()
    case .collectionWaterfall:
      destination = FKStickyWaterfallCollectionViewController()
    case .customOffset:
      destination = FKStickyAnimationDemoViewController(mode: .customOffset)
    case .alphaAnimation:
      destination = FKStickyAnimationDemoViewController(mode: .alpha)
    case .backgroundAnimation:
      destination = FKStickyAnimationDemoViewController(mode: .backgroundColor)
    case .scaleAnimation:
      destination = FKStickyAnimationDemoViewController(mode: .scale)
    case .stateCallback:
      destination = FKStickyAnimationDemoViewController(mode: .stateCallback)
    case .toggleSticky:
      destination = FKStickyAnimationDemoViewController(mode: .toggleSticky)
    case .globalConfiguration:
      destination = FKStickyGlobalConfigDemoViewController()
    case .swiftUI:
      destination = FKStickySwiftUIHostViewController()
    case .darkMode:
      destination = FKStickyDarkModeDemoViewController()
    case .rotation:
      destination = FKStickyRotationDemoViewController()
    case .performance:
      destination = FKStickyPerformanceDemoViewController()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
}
