import UIKit
import FKCompositeKit

/// Three equal-width tabs; body area left empty.
final class FKFilterTableHostExampleViewController: UIViewController {
  private enum TabID: String {
    case platform
    case allCourses
    case tags
  }

  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let tabStrip = FKFilterExampleTabStripView()

  private var courseModel: FKFilterTwoColumnModel?
  private var platformSections: [FKFilterSection] = []
  private var tagsSections: [FKFilterSection] = []

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelSupport.makePanelFactory(
    knowledgeModel: { nil },
    courseModel: { [weak self] in self?.courseModel },
    fileTypeSections: { [] },
    platformSections: { [weak self] in self?.platformSections ?? [] },
    tagsSections: { [weak self] in self?.tagsSections ?? [] },
    sortSection: { nil },
    onKnowledgeChange: { _ in },
    onCourseChange: { [weak self] in self?.courseModel = $0 },
    onFileTypeChange: { _ in },
    onPlatformChange: { [weak self] in self?.platformSections = $0 },
    onTagsChange: { [weak self] in self?.tagsSections = $0 },
    onSortChange: { _ in },
    onTagsSelectionEmptied: nil
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
          subtitle: "可多选",
          allowsMultipleSelection: true,
          stripMetrics: sm
        ),
      ],
      panelFactory: panelFactory,
      configuration: FKFilterExampleAppearance.equalThreeAnchoredConfiguration(),
      tabBarHost: tabStrip
    )
  }()

  private var filterStripView: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Equal · business"
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
      async let c = provider.fetchCourseTwoColumnModel()
      async let platform = provider.fetchPlatformSections()
      async let tags = provider.fetchTagsSections()
      courseModel = await c
      platformSections = await platform
      tagsSections = await tags
      filterHost.invalidateCachedPanelContent(for: TabID.platform.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.allCourses.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.tags.rawValue)
    }
  }
}
