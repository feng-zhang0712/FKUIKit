import UIKit
import FKCompositeKit

/// `FKFilterController` + six mock filters (scrollable strip, intrinsic tab widths).
final class FKFilterExampleViewController: UIViewController {
  private enum TabID: String {
    case knowledge
    case allCourses
    case fileType
    case platform
    case tags
    case sort
  }

  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let tabStrip = FKFilterExampleTabStripView()

  private var knowledgeModel: FKFilterTwoColumnModel?
  private var courseModel: FKFilterTwoColumnModel?
  private var fileTypeSections: [FKFilterSection] = []
  private var platformSections: [FKFilterSection] = []
  private var tagsSections: [FKFilterSection] = []
  private var sortSection: FKFilterSection?
  private var tagsTabTitle = "标签"

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelSupport.makePanelFactory(
    knowledgeModel: { [weak self] in self?.knowledgeModel },
    courseModel: { [weak self] in self?.courseModel },
    fileTypeSections: { [weak self] in self?.fileTypeSections ?? [] },
    platformSections: { [weak self] in self?.platformSections ?? [] },
    tagsSections: { [weak self] in self?.tagsSections ?? [] },
    sortSection: { [weak self] in self?.sortSection },
    onKnowledgeChange: { [weak self] in self?.knowledgeModel = $0 },
    onCourseChange: { [weak self] in self?.courseModel = $0 },
    onFileTypeChange: { [weak self] in self?.fileTypeSections = $0 },
    onPlatformChange: { [weak self] in self?.platformSections = $0 },
    onTagsChange: { [weak self] in self?.tagsSections = $0 },
    onSortChange: { [weak self] in self?.sortSection = $0 },
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
      configuration: FKFilterExampleAppearance.hubAnchoredConfiguration(),
      tabBarHost: tabStrip
    )
  }()

  private var filterStripView: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Full demo"
    view.backgroundColor = .systemBackground
    embedFilter()
    setupBodyPlaceholder()
    loadData()
  }

  private func embedFilter() {
    addChild(filterHost)
    filterHost.loadViewIfNeeded()
    guard let fv = filterHost.view else { return }
    filterStripView = fv
    fv.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(fv)
    NSLayoutConstraint.activate([
      fv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      fv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      fv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      fv.heightAnchor.constraint(equalToConstant: 56),
    ])
    filterHost.didMove(toParent: self)
    filterHost.pinAnchoredPresentationOverlay(to: view)
  }

  private func setupBodyPlaceholder() {
    let filler = UIView()
    filler.backgroundColor = .systemBackground
    filler.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(filler)
    NSLayoutConstraint.activate([
      filler.topAnchor.constraint(equalTo: filterStripView!.bottomAnchor),
      filler.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      filler.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      filler.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
  }

  private func loadData() {
    Task { @MainActor in
      async let m = provider.fetchKnowledgeTwoColumnModel()
      async let c = provider.fetchCourseTwoColumnModel()
      async let file = provider.fetchFileTypeSections()
      async let platform = provider.fetchPlatformSections()
      async let tags = provider.fetchTagsSections()
      async let sort = provider.fetchSortSection()
      knowledgeModel = await m
      courseModel = await c
      fileTypeSections = await file
      platformSections = await platform
      tagsSections = await tags
      sortSection = await sort
      filterHost.invalidateCachedPanelContent(for: TabID.knowledge.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.allCourses.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.fileType.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.platform.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.tags.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.sort.rawValue)
    }
  }

  private static func makeTabs(tagsTitle: @escaping () -> String) -> [FKFilterTab<String>] {
    let sm = FKFilterExampleAppearance.filterStripMetrics
    return [
      .init(
        id: TabID.knowledge.rawValue, panelKind: .hierarchy, title: "知识目录",
        stripMetrics: sm
      ),
      .init(
        id: TabID.allCourses.rawValue, panelKind: .dualHierarchy, title: "全部课程", subtitle: "精选",
        stripMetrics: sm
      ),
      .init(
        id: TabID.fileType.rawValue, panelKind: .gridPrimary, title: "全部",
        stripMetrics: sm
      ),
      .init(
        id: TabID.platform.rawValue, panelKind: .gridSecondary, title: "课程归属",
        stripMetrics: sm
      ),
      FKFilterTab(
        id: TabID.tags.rawValue,
        panelKind: .tags,
        title: tagsTitle,
        subtitle: { Optional("可多选") },
        allowsMultipleSelection: true,
        stripMetrics: sm
      ),
      .init(
        id: TabID.sort.rawValue, panelKind: .singleList, title: "最新",
        stripMetrics: sm
      ),
    ]
  }
}
