import UIKit
import FKBusinessKit

private final class FKFilterTopHairlineWrapperViewController: UIViewController {
  private let contentVC: UIViewController
  private let hairline = UIView()
  private var hairlineHeightConstraint: NSLayoutConstraint?

  init(contentVC: UIViewController) {
    self.contentVC = contentVC
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var preferredContentSize: CGSize {
    get {
      let inner = contentVC.preferredContentSize
      guard inner.height > 0 else { return .zero }
      return CGSize(width: inner.width, height: inner.height + currentHairlineHeight())
    }
    set { super.preferredContentSize = newValue }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    hairline.backgroundColor = .separator
    hairline.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hairline)
    addChild(contentVC)
    contentVC.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(contentVC.view)
    contentVC.didMove(toParent: self)
    let hairlineHeight = currentHairlineHeight()
    hairlineHeightConstraint = hairline.heightAnchor.constraint(equalToConstant: hairlineHeight)
    NSLayoutConstraint.activate([
      hairline.topAnchor.constraint(equalTo: view.topAnchor),
      hairline.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hairline.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hairlineHeightConstraint,
      contentVC.view.topAnchor.constraint(equalTo: hairline.bottomAnchor),
      contentVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ].compactMap { $0 })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    hairlineHeightConstraint?.constant = currentHairlineHeight()
  }

  private func currentHairlineHeight() -> CGFloat {
    let scale = view.window?.windowScene?.screen.scale ?? traitCollection.displayScale
    return 1 / max(scale, 1)
  }
}

enum FKFilterExamplePanelSupport {
  @MainActor
  static func loadingPanel(title: String) -> UIViewController {
    let vc = UIViewController()
    vc.preferredContentSize = CGSize(width: 0, height: 72)
    vc.view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = title
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .body)
    label.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 20),
      label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
      label.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -20),
    ])
    return wrapWithTopHairline(vc)
  }

  @MainActor
  static func wrapWithTopHairline(_ contentVC: UIViewController) -> UIViewController {
    FKFilterTopHairlineWrapperViewController(contentVC: contentVC)
  }

  @MainActor
  static func makePanel(
    kind: FKFilterBarPresentation.PanelKind,
    filterBar: FKFilterBarPresentation,
    knowledgeModel: FKFilterTwoColumnModel?,
    courseModel: FKFilterTwoColumnModel?,
    fileTypeSections: [FKFilterSection],
    platformSections: [FKFilterSection],
    tagsSections: [FKFilterSection],
    sortSection: FKFilterSection?,
    onKnowledgeChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onCourseChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onFileTypeChange: @escaping ([FKFilterSection]) -> Void,
    onPlatformChange: @escaping ([FKFilterSection]) -> Void,
    onTagsChange: @escaping ([FKFilterSection]) -> Void,
    onSortChange: @escaping (FKFilterSection) -> Void
  ) -> UIViewController? {
    switch kind {
    case .twoColumn:
      guard let model = knowledgeModel else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterTwoColumnViewController(
        model: model,
        onChange: onKnowledgeChange,
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .twoColumn, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .twoColumn)
      )
      return wrapWithTopHairline(vc)
    case .courseTwoColumn:
      guard let model = courseModel else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterCourseTwoColumnViewController(
        model: model,
        onChange: onCourseChange,
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .courseTwoColumn, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .courseTwoColumn)
      )
      return wrapWithTopHairline(vc)
    case .fileTypeChips:
      guard !fileTypeSections.isEmpty else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterChipsViewController(
        sections: fileTypeSections,
        configuration: .init(columns: 4),
        onChange: onFileTypeChange,
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .fileTypeChips, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .fileTypeChips)
      )
      return wrapWithTopHairline(vc)
    case .platformChips:
      guard !platformSections.isEmpty else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterChipsViewController(
        sections: platformSections,
        configuration: .init(columns: 2),
        onChange: onPlatformChange,
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .platformChips, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .platformChips)
      )
      return wrapWithTopHairline(vc)
    case .tagsChips:
      guard !tagsSections.isEmpty else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterChipsViewController(
        sections: tagsSections,
        configuration: .init(columns: 2, maxPresentedHeight: 320),
        onChange: { newSections in
          onTagsChange(newSections)
          let selectedCount = newSections.flatMap(\.items).filter(\.isSelected).count
          if selectedCount == 0 { filterBar.updateBarTitle("标签", for: .tagsChips) }
        },
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .tagsChips, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .tagsChips)
      )
      return wrapWithTopHairline(vc)
    case .sortList:
      guard let section = sortSection else { return loadingPanel(title: "Loading…") }
      let vc = FKFilterSingleListViewController(
        section: section,
        onChange: onSortChange,
        onSelectItem: { sectionID, item, mode in
          filterBar.handlePanelSelection(panelKind: .sortList, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: filterBar.isMultipleSelectionEnabled(for: .sortList),
        centerText: true
      )
      return wrapWithTopHairline(vc)
    }
  }
}
