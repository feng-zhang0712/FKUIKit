import UIKit
import FKBusinessKit

final class FKFilterCustomViewHostExampleViewController: UIViewController {
  private let provider: FKFilterExampleDataProviding = FKFilterExampleMockDataProvider()
  private let filterHost = FKFilterBarHost()
  private var filterBar: FKFilterBarPresentation { filterHost.filterBar }
  private var knowledgeModel: FKFilterTwoColumnModel?
  private var fileTypeSections: [FKFilterSection] = []
  private var sortSection: FKFilterSection?
  private let cardView = UIView()
  private let titleLabel = UILabel()
  private let bodyLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter + Custom view"
    view.backgroundColor = .systemBackground
    filterHost.installBelowTopSafeArea(of: self)
    filterBar.setItems([
      .init(id: .init(rawValue: "knowledge"), title: "知识目录", panelKind: .twoColumn),
      .init(id: .init(rawValue: "type"), title: "全部", panelKind: .fileTypeChips),
      .init(id: .init(rawValue: "sort"), title: "最新", panelKind: .sortList),
    ])
    filterBar.makePanelViewController = { [weak self] kind in
      guard let self else { return nil }
      return FKFilterExamplePanelSupport.makePanel(
        kind: kind,
        filterBar: self.filterBar,
        knowledgeModel: self.knowledgeModel,
        courseModel: nil,
        fileTypeSections: self.fileTypeSections,
        platformSections: [],
        tagsSections: [],
        sortSection: self.sortSection,
        onKnowledgeChange: { [weak self] in self?.knowledgeModel = $0 },
        onCourseChange: { _ in },
        onFileTypeChange: { [weak self] in self?.fileTypeSections = $0 },
        onPlatformChange: { _ in },
        onTagsChange: { _ in },
        onSortChange: { [weak self] in self?.sortSection = $0 }
      )
    }
    filterBar.onBarTabSelected = { [weak self] index, model in
      self?.appendBody("Bar: \(model.title) (index \(index))")
    }
    filterBar.onSelectItem = { [weak self] kind, item, _ in
      self?.appendBody("Panel \(kind): “\(item.title)”")
    }
    cardView.backgroundColor = .secondarySystemGroupedBackground
    cardView.layer.cornerRadius = 12
    cardView.layer.cornerCurve = .continuous
    cardView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "Custom content"
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.textColor = .label
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    bodyLabel.text = "Interaction log:\n—"
    bodyLabel.numberOfLines = 0
    bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(cardView)
    cardView.addSubview(titleLabel)
    cardView.addSubview(bodyLabel)
    NSLayoutConstraint.activate([
      cardView.topAnchor.constraint(equalTo: filterHost.contentLayoutGuide.topAnchor, constant: 16),
      cardView.leadingAnchor.constraint(equalTo: filterHost.contentLayoutGuide.leadingAnchor, constant: 16),
      cardView.trailingAnchor.constraint(equalTo: filterHost.contentLayoutGuide.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
      bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      bodyLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
      bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
      bodyLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
    ])
    loadData()
  }

  private func loadData() {
    Task { @MainActor in
      async let m = provider.fetchKnowledgeTwoColumnModel()
      async let file = provider.fetchFileTypeSections()
      async let sort = provider.fetchSortSection()
      knowledgeModel = await m
      fileTypeSections = await file
      sortSection = await sort
    }
  }

  private func appendBody(_ line: String) {
    let base = bodyLabel.text ?? ""
    let trimmed: String
    if base.hasPrefix("Interaction log:\n") {
      let rest = base.dropFirst("Interaction log:\n".count)
      trimmed = rest == "—" ? "" : String(rest)
    } else {
      trimmed = base
    }
    let next = trimmed.isEmpty ? line : trimmed + "\n" + line
    let lines = next.split(separator: "\n", omittingEmptySubsequences: false)
    let tail = lines.suffix(12).joined(separator: "\n")
    bodyLabel.text = "Interaction log:\n" + tail
  }
}
