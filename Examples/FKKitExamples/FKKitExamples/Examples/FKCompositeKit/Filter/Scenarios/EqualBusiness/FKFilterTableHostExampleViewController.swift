import UIKit
import FKCompositeKit

/// Three equal-width tabs (platform · course grid · tags); body area left empty.
final class FKFilterTableHostExampleViewController: UIViewController {
  private enum TabID: String, CaseIterable {
    case platform
    case allCourses
    case tags
  }

  private let demoState = FKFilterExampleState.presetEqualBusiness()
  private let tabStrip = FKFilterExampleTabStripView()

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelFactoryBuilder.makeFactory(
    bindingTo: demoState
  )

  private lazy var filterHost: FKFilterController<String> = {
    let sm = FKFilterExampleAppearance.filterStripMetrics
    return FKFilterController(
      tabs: [
        .init(
          id: TabID.platform.rawValue, panelKind: .gridSecondary, title: "课程归属",
          stripMetrics: sm
        ),
        .init(
          id: TabID.allCourses.rawValue, panelKind: .dualHierarchy, title: "全部课程",
          stripMetrics: sm
        ),
        .init(
          id: TabID.tags.rawValue,
          panelKind: .tags,
          title: "标签",
          stripMetrics: sm
        ),
      ],
      panelFactory: panelFactory,
      configuration: FKFilterExampleAppearance.equalThreeAnchoredConfiguration(),
      tabBarHost: tabStrip
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Equal · business"
    view.backgroundColor = .systemBackground
    guard let strip = FKFilterExampleChrome.embed(
      filterHost: filterHost,
      in: self,
      topAnchor: view.safeAreaLayoutGuide.topAnchor,
      overlayHost: view,
      logSelection: true
    ) else { return }
    FKFilterExampleChrome.installBodyPlaceholder(below: strip.bottomAnchor, in: self)
    TabID.allCases.forEach { filterHost.invalidateCachedPanelContent(for: $0.rawValue) }
  }
}
