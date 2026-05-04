import UIKit
import FKCompositeKit

/// Three equal-width tabs (knowledge · file types · sort); body area left empty.
final class FKFilterCustomViewHostExampleViewController: UIViewController {
  private enum TabID: String, CaseIterable {
    case knowledge
    case fileType
    case sort
  }

  private let filterConfiguration = FKFilterExampleAppearance.makeEqualThreeFilterConfiguration()
  private let demoState = FKFilterExampleState.presetEqualKnowledge()
  private let tabStrip = FKFilterExampleTabStripView()

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelFactoryBuilder.makeFactory(
    bindingTo: demoState,
    filterConfiguration: filterConfiguration
  )

  private lazy var filterHost: FKFilterController<String> = {
    FKFilterController(
      tabs: [
        .init(
          id: TabID.knowledge.rawValue, panelKind: .hierarchy, title: "知识目录"
        ),
        .init(
          id: TabID.fileType.rawValue, panelKind: .gridPrimary, title: "全部"
        ),
        .init(
          id: TabID.sort.rawValue, panelKind: .singleList, title: "最新"
        ),
      ],
      panelFactory: panelFactory,
      filterConfiguration: filterConfiguration,
      tabBarHost: tabStrip
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Equal · knowledge"
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
