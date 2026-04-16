import UIKit
import FKBusinessKit

final class FKFilterTableHostExampleViewController: UIViewController {
  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let filterHost = FKFilterBarHost()
  private var filterBar: FKFilterBarPresentation { filterHost.filterBar }
  private var courseModel: FKFilterTwoColumnModel?
  private var platformSections: [FKFilterSection] = []
  private var tagsSections: [FKFilterSection] = []
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var logLines: [String] = ["Use the filter bar, then pick an option. Events append here."]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter + TableView"
    view.backgroundColor = .systemBackground
    filterHost.installBelowTopSafeArea(of: self)
    filterBar.setItems([
      .init(id: .init(rawValue: "platform"), title: "课程归属", panelKind: .platformChips),
      .init(id: .init(rawValue: "all-courses"), title: "全部课程", panelKind: .courseTwoColumn),
      .init(id: .init(rawValue: "tags"), title: "标签", panelKind: .tagsChips),
    ])
    filterBar.makePanelViewController = { [weak self] kind in
      guard let self else { return nil }
      return FKFilterExamplePanelSupport.makePanel(
        kind: kind,
        filterBar: self.filterBar,
        knowledgeModel: nil,
        courseModel: self.courseModel,
        fileTypeSections: [],
        platformSections: self.platformSections,
        tagsSections: self.tagsSections,
        sortSection: nil,
        onKnowledgeChange: { _ in },
        onCourseChange: { [weak self] in self?.courseModel = $0 },
        onFileTypeChange: { _ in },
        onPlatformChange: { [weak self] in self?.platformSections = $0 },
        onTagsChange: { [weak self] in self?.tagsSections = $0 },
        onSortChange: { _ in }
      )
    }
    filterBar.onBarTabSelected = { [weak self] index, model in
      self?.appendLog("Bar: \(model.title) (index \(index))")
    }
    filterBar.onSelectItem = { [weak self] kind, item, _ in
      self?.appendLog("Panel \(kind): selected “\(item.title)”")
    }

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.dataSource = self
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: filterHost.contentLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: filterHost.contentLayoutGuide.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: filterHost.contentLayoutGuide.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: filterHost.contentLayoutGuide.bottomAnchor),
    ])
    loadData()
  }

  private func loadData() {
    Task { @MainActor in
      async let c = provider.fetchCourseTwoColumnModel()
      async let platform = provider.fetchPlatformSections()
      async let tags = provider.fetchTagsSections()
      courseModel = await c
      platformSections = await platform
      tagsSections = await tags
    }
  }

  private func appendLog(_ line: String) {
    logLines.append(line)
    if logLines.count > 80 { logLines.removeFirst(logLines.count - 80) }
    tableView.reloadData()
  }
}

extension FKFilterTableHostExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    logLines.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = logLines[indexPath.row]
    config.textProperties.numberOfLines = 0
    config.textProperties.font = .preferredFont(forTextStyle: .footnote)
    cell.contentConfiguration = config
    cell.selectionStyle = .none
    return cell
  }
}
