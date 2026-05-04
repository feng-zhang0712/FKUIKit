import UIKit
import FKCompositeKit

/// ``FKFilterController`` + six filters (scrollable strip, intrinsic tab widths).
final class FKFilterExampleViewController: UIViewController {
  private enum TabID: String, CaseIterable {
    case knowledge
    case allCourses
    case fileType
    case platform
    case tags
    case sort
  }

  private let filterConfiguration = FKFilterExampleAppearance.makeHubFilterConfiguration()
  private let demoState = FKFilterExampleState.presetFullHub()
  private let tabStrip = FKFilterExampleTabStripView()
  private var tagsTabTitle = "标签"

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelFactoryBuilder.makeFactory(
    bindingTo: demoState,
    filterConfiguration: filterConfiguration,
    onTagsSelectionEmptied: { [weak self] in
      guard let self else { return }
      self.tagsTabTitle = "标签"
      self.filterHost.dropdownController.reloadTabBarItems()
    }
  )

  private lazy var filterHost: FKFilterController<String> = {
    FKFilterController(
      tabs: Self.makeTabs(tagsTitle: { [weak self] in self?.tagsTabTitle ?? "标签" }),
      panelFactory: panelFactory,
      filterConfiguration: filterConfiguration,
      tabBarHost: tabStrip
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Full demo"
    view.backgroundColor = .systemBackground
    guard let strip = FKFilterExampleChrome.embed(
      filterHost: filterHost,
      in: self,
      topAnchor: view.safeAreaLayoutGuide.topAnchor,
      overlayHost: view,
      logSelection: true
    ) else { return }
    FKFilterExampleChrome.installBodyPlaceholder(below: strip.bottomAnchor, in: self)
    reloadAllPanels()
  }

  private func reloadAllPanels() {
    TabID.allCases.forEach { filterHost.invalidateCachedPanelContent(for: $0.rawValue) }
  }

  private static func makeTabs(tagsTitle: @escaping () -> String) -> [FKFilterTab<String>] {
    [
      .init(
        id: TabID.knowledge.rawValue, panelKind: .hierarchy, title: "知识目录"
      ),
      .init(
        id: TabID.allCourses.rawValue, panelKind: .dualHierarchy, title: "全部课程"
      ),
      .init(
        id: TabID.fileType.rawValue, panelKind: .gridPrimary, title: "全部"
      ),
      .init(
        id: TabID.platform.rawValue, panelKind: .gridSecondary, title: "课程归属"
      ),
      FKFilterTab(
        id: TabID.tags.rawValue,
        panelKind: .tags,
        title: tagsTitle,
        subtitle: { Optional("可多选") },
        allowsMultipleSelection: true
      ),
      .init(
        id: TabID.sort.rawValue, panelKind: .singleList, title: "最新"
      ),
    ]
  }
}
