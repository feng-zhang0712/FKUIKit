import UIKit
import FKCompositeKit

/// Hosts `FKFilterBarPresentation` with mock hierarchical / grid / tag data from `FKFilterExampleMockDataProvider`.
final class FKFilterExampleViewController: UIViewController {
  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let filterHost = FKFilterBarHost()
  private var filterBar: FKFilterBarPresentation { filterHost.filterBar }
  private let barTabHintLabel = UILabel()

  private var knowledgeModel: FKFilterTwoColumnModel?
  private var courseModel: FKFilterTwoColumnModel?
  private var fileTypeSections: [FKFilterSection] = []
  private var platformSections: [FKFilterSection] = []
  private var tagsSections: [FKFilterSection] = []
  private var sortSection: FKFilterSection?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter (FKBarPresentation)"
    view.backgroundColor = .systemBackground
    setupFilterHost()
    setupBelowPlaceholder()
    configureBarItems()
    loadData()
  }

  private func setupFilterHost() {
    filterHost.installBelowTopSafeArea(of: self)
    filterBar.makePanelViewController = { [weak self] kind in
      guard let self else { return nil }
      return self.makePanel(kind: kind)
    }
    filterBar.onBarTabSelected = { [weak self] index, model in
      self?.barTabHintLabel.text = "Last bar segment: \(model.title) (index \(index))"
    }
  }

  private func setupBelowPlaceholder() {
    barTabHintLabel.numberOfLines = 0
    barTabHintLabel.textAlignment = .center
    barTabHintLabel.textColor = .tertiaryLabel
    barTabHintLabel.font = .preferredFont(forTextStyle: .caption1)
    barTabHintLabel.text = "Last bar segment: —"
    barTabHintLabel.translatesAutoresizingMaskIntoConstraints = false

    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .body)
    label.text =
      "Filter bar is hosted by `FKFilterBarHost` under the safe area.\n" +
      "Pin scroll views or other content to `contentLayoutGuide` below the bar."
    label.translatesAutoresizingMaskIntoConstraints = false

    let tableDemoButton = makeDemoNavigationButton(title: "TableView host (3 filters)")
    tableDemoButton.addTarget(self, action: #selector(openTableHostExample), for: .touchUpInside)

    let customDemoButton = makeDemoNavigationButton(title: "Custom view host (3 filters)")
    customDemoButton.addTarget(self, action: #selector(openCustomViewHostExample), for: .touchUpInside)

    view.addSubview(barTabHintLabel)
    view.addSubview(label)
    view.addSubview(tableDemoButton)
    view.addSubview(customDemoButton)
    NSLayoutConstraint.activate([
      barTabHintLabel.topAnchor.constraint(equalTo: filterHost.contentLayoutGuide.topAnchor, constant: 12),
      barTabHintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      barTabHintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      label.topAnchor.constraint(equalTo: barTabHintLabel.bottomAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      tableDemoButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
      tableDemoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      tableDemoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      customDemoButton.topAnchor.constraint(equalTo: tableDemoButton.bottomAnchor, constant: 12),
      customDemoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      customDemoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
  }

  private func makeDemoNavigationButton(title: String) -> UIButton {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.baseBackgroundColor = .systemBlue
    config.baseForegroundColor = .white
    config.cornerStyle = .medium
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var out = incoming
      out.font = UIFont.preferredFont(forTextStyle: .subheadline)
      return out
    }
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  @objc private func openTableHostExample() {
    navigationController?.pushViewController(FKFilterTableHostExampleViewController(), animated: true)
  }

  @objc private func openCustomViewHostExample() {
    navigationController?.pushViewController(FKFilterCustomViewHostExampleViewController(), animated: true)
  }

  private func configureBarItems() {
    var richTitle = AttributedString("全部课程")
    richTitle.foregroundColor = .systemRed
    richTitle.font = .preferredFont(forTextStyle: .subheadline)

    var richSubtitle = AttributedString("推荐")
    richSubtitle.foregroundColor = .systemOrange
    richSubtitle.font = .preferredFont(forTextStyle: .caption2)

    filterBar.setItems([
      .init(id: .init(rawValue: "knowledge"), title: "知识目录", panelKind: .hierarchy),
      .init(
        id: .init(rawValue: "all-courses"),
        title: "全部课程",
        subtitle: "精选",
        attributedTitle: richTitle,
        attributedSubtitle: richSubtitle,
        panelKind: .dualHierarchy
      ),
      .init(id: .init(rawValue: "type"), title: "全部", panelKind: .gridPrimary),
      .init(id: .init(rawValue: "platform"), title: "课程归属", panelKind: .gridSecondary),
      .init(id: .init(rawValue: "tags"), title: "标签", subtitle: "可多选", panelKind: .tags),
      .init(id: .init(rawValue: "sort"), title: "最新", panelKind: .singleList),
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
    }
  }

  private func makePanel(kind: FKFilterBarPresentation.PanelKind) -> UIViewController? {
    FKFilterExamplePanelSupport.makePanel(
      kind: kind,
      filterBar: filterBar,
      knowledgeModel: knowledgeModel,
      courseModel: courseModel,
      fileTypeSections: fileTypeSections,
      platformSections: platformSections,
      tagsSections: tagsSections,
      sortSection: sortSection,
      onKnowledgeChange: { [weak self] in self?.knowledgeModel = $0 },
      onCourseChange: { [weak self] in self?.courseModel = $0 },
      onFileTypeChange: { [weak self] in self?.fileTypeSections = $0 },
      onPlatformChange: { [weak self] in self?.platformSections = $0 },
      onTagsChange: { [weak self] in self?.tagsSections = $0 },
      onSortChange: { [weak self] in self?.sortSection = $0 }
    )
  }
}
