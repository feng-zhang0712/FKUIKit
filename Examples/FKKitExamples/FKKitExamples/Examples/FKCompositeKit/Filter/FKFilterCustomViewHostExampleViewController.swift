import UIKit
import FKCompositeKit

/// Three equal-width tabs; body area left empty.
final class FKFilterCustomViewHostExampleViewController: UIViewController {
  private enum TabID: String {
    case knowledge
    case fileType
    case sort
  }

  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let tabStrip = FKFilterExampleTabStripView()

  private var knowledgeModel: FKFilterTwoColumnModel?
  private var fileTypeSections: [FKFilterSection] = []
  private var sortSection: FKFilterSection?

  private lazy var panelFactory: FKFilterPanelFactory = FKFilterExamplePanelSupport.makePanelFactory(
    knowledgeModel: { [weak self] in self?.knowledgeModel },
    courseModel: { nil },
    fileTypeSections: { [weak self] in self?.fileTypeSections ?? [] },
    platformSections: { [] },
    tagsSections: { [] },
    sortSection: { [weak self] in self?.sortSection },
    onKnowledgeChange: { [weak self] in self?.knowledgeModel = $0 },
    onCourseChange: { _ in },
    onFileTypeChange: { [weak self] in self?.fileTypeSections = $0 },
    onPlatformChange: { _ in },
    onTagsChange: { _ in },
    onSortChange: { [weak self] in self?.sortSection = $0 },
    onTagsSelectionEmptied: nil
  )

  private lazy var filterHost: FKFilterController<String> = {
    let ty = FKFilterExampleAppearance.titleStyle
    let st = FKFilterExampleAppearance.subtitleStyle
    let cs = FKFilterExampleAppearance.chevronSize
    let csp = FKFilterExampleAppearance.chevronSpacing
    let tss = FKFilterExampleAppearance.titleSubtitleSpacing
    return FKFilterController(
      tabs: [
        .init(
          id: TabID.knowledge.rawValue, panelKind: .hierarchy, title: "知识目录",
          titleTextStyle: ty, subtitleTextStyle: st, chevronSize: cs, chevronSpacing: csp, titleSubtitleSpacing: tss
        ),
        .init(
          id: TabID.fileType.rawValue, panelKind: .gridPrimary, title: "全部",
          titleTextStyle: ty, subtitleTextStyle: st, chevronSize: cs, chevronSpacing: csp, titleSubtitleSpacing: tss
        ),
        .init(
          id: TabID.sort.rawValue, panelKind: .singleList, title: "最新",
          titleTextStyle: ty, subtitleTextStyle: st, chevronSize: cs, chevronSpacing: csp, titleSubtitleSpacing: tss
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
    title = "Equal · knowledge"
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
      async let file = provider.fetchFileTypeSections()
      async let sort = provider.fetchSortSection()
      knowledgeModel = await m
      fileTypeSections = await file
      sortSection = await sort
      filterHost.invalidateCachedPanelContent(for: TabID.knowledge.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.fileType.rawValue)
      filterHost.invalidateCachedPanelContent(for: TabID.sort.rawValue)
    }
  }
}
