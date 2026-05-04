import UIKit

/// Two-column panel controller: left category list + right option list (both `UITableView`).
///
/// Layout:
/// - Left: `FKFilterTwoColumnModel.categories`
/// - Right: sections for the selected category (`sectionsByCategoryID[selectedCategoryID]`)
///
/// Capabilities:
/// - Section header display (and optional header selection)
/// - Single-select scope:
///   - `.withinSection`: single selection only affects the tapped section
///   - `.globalAcrossSections`: single selection clears other sections (useful for "course catalog" style)
/// - Height controlled via `Configuration.heightBehavior`
public final class FKFilterTwoColumnListViewController: UIViewController {
  public typealias LeftCellContentConfiguration = (
    _ cell: UITableViewCell,
    _ indexPath: IndexPath,
    _ category: FKFilterTwoColumnModel.Category
  ) -> Void

  public typealias RightCellContentConfiguration = (
    _ cell: UITableViewCell,
    _ indexPath: IndexPath,
    _ item: FKFilterOptionItem,
    _ section: FKFilterSection
  ) -> Void

  public enum SingleSelectionScope {
    case withinSection
    case globalAcrossSections
  }

  public struct RightHeaderStyle {
    public var normalTextColor: UIColor
    public var selectedTextColor: UIColor
    public var font: UIFont
    public var contentInsets: UIEdgeInsets
    public var minimumHeight: CGFloat

    public init(
      normalTextColor: UIColor = .secondaryLabel,
      selectedTextColor: UIColor = .systemRed,
      font: UIFont = {
        let base = UIFont.preferredFont(forTextStyle: .subheadline)
        return UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
      }(),
      contentInsets: UIEdgeInsets = .init(top: 10, left: 16, bottom: 10, right: 16),
      minimumHeight: CGFloat = 44
    ) {
      self.normalTextColor = normalTextColor
      self.selectedTextColor = selectedTextColor
      self.font = font
      self.contentInsets = contentInsets
      self.minimumHeight = minimumHeight
    }
  }

  public struct Configuration {
    public var rowHeight: CGFloat
    public var sectionHeaderHeight: CGFloat
    public var leftColumnWidthRatio: CGFloat
    public var leftCellStyle: FKFilterListCellStyle
    public var rightCellStyle: FKFilterListCellStyle
    public var leftBackgroundColor: UIColor
    public var rightBackgroundColor: UIColor
    public var rightSeparatorInset: UIEdgeInsets
    public var rightSectionHeaderStyle: RightHeaderStyle
    public var allowsSelectingSectionHeader: Bool
    public var singleSelectionScope: SingleSelectionScope
    public var heightBehavior: FKFilterPanelHeightBehavior
    /// Optional hook for left table cell customization.
    public var configureLeftCell: LeftCellContentConfiguration?
    /// Optional hook for right table cell customization.
    public var configureRightCell: RightCellContentConfiguration?

    public init(
      rowHeight: CGFloat = 44,
      sectionHeaderHeight: CGFloat = 28,
      leftColumnWidthRatio: CGFloat = 0.30,
      leftCellStyle: FKFilterListCellStyle = .init(
        rowBackgroundColor: UIColor.systemGray6.withAlphaComponent(0.6),
        selectedRowBackgroundColor: .systemBackground
      ),
      rightCellStyle: FKFilterListCellStyle = .init(),
      leftBackgroundColor: UIColor = UIColor.systemGray6.withAlphaComponent(0.6),
      rightBackgroundColor: UIColor = .systemBackground,
      rightSeparatorInset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16),
      rightSectionHeaderStyle: RightHeaderStyle = .init(),
      allowsSelectingSectionHeader: Bool = false,
      singleSelectionScope: SingleSelectionScope = .withinSection,
      heightBehavior: FKFilterPanelHeightBehavior = .automatic(
        minimum: 120,
        screenMinimumFraction: 0.38,
        maximumScreenFraction: 0.88
      ),
      configureLeftCell: LeftCellContentConfiguration? = nil,
      configureRightCell: RightCellContentConfiguration? = nil
    ) {
      self.rowHeight = rowHeight
      self.sectionHeaderHeight = sectionHeaderHeight
      self.leftColumnWidthRatio = max(0.2, min(leftColumnWidthRatio, 0.6))
      self.leftCellStyle = leftCellStyle
      self.rightCellStyle = rightCellStyle
      self.leftBackgroundColor = leftBackgroundColor
      self.rightBackgroundColor = rightBackgroundColor
      self.rightSeparatorInset = rightSeparatorInset
      self.rightSectionHeaderStyle = rightSectionHeaderStyle
      self.allowsSelectingSectionHeader = allowsSelectingSectionHeader
      self.singleSelectionScope = singleSelectionScope
      self.heightBehavior = heightBehavior
      self.configureLeftCell = configureLeftCell
      self.configureRightCell = configureRightCell
    }

    public static var sectionHeaderSelectable: Configuration {
      .init(
        rowHeight: 46,
        sectionHeaderHeight: 44,
        allowsSelectingSectionHeader: true,
        singleSelectionScope: .globalAcrossSections,
        heightBehavior: .automatic(
          minimum: 120,
          screenMinimumFraction: 0.38,
          maximumScreenFraction: 0.88
        )
      )
    }
  }

  private var model: FKFilterTwoColumnModel
  private let configuration: Configuration
  private let onChange: (FKFilterTwoColumnModel) -> Void
  private let onSelection: ((FKFilterPanelSelection) -> Void)?
  private let allowsMultipleSelection: Bool

  private let leftTable = UITableView(frame: .zero, style: .plain)
  private let rightTable = UITableView(frame: .zero, style: .plain)
  private var selectedHeaderSectionID: FKFilterID?
  /// Avoids redundant anchor relayout when computed height is unchanged (reduces flicker).
  private var lastPublishedPreferredHeight: CGFloat?

  private static let fallbackSizingRowHeight: CGFloat = 44
  private static let fallbackSizingSectionHeaderHeight: CGFloat = 28

  public init(
    model: FKFilterTwoColumnModel,
    configuration: Configuration = .init(),
    onChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onSelection: ((FKFilterPanelSelection) -> Void)? = nil,
    allowsMultipleSelection: Bool = false
  ) {
    self.model = model
    self.configuration = configuration
    self.onChange = onChange
    self.onSelection = onSelection
    self.allowsMultipleSelection = allowsMultipleSelection
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public override var preferredContentSize: CGSize {
    get { CGSize(width: 0, height: resolvedPreferredContentHeight()) }
    set { super.preferredContentSize = newValue }
  }

  /// Preferred height from current model (left row count vs right rows/headers), after ``FKFilterPanelHeightBehavior``.
  private func resolvedPreferredContentHeight() -> CGFloat {
    let leftRows = model.categories.count
    let sections = rightSections()
    let rightRows = sections.reduce(0) { partial, sec in partial + sec.items.count }
    let titledSectionCount = sections.filter { ($0.title ?? "").isEmpty == false }.count
    let sectionHeaderHeight = max(configuration.sectionHeaderHeight, Self.fallbackSizingSectionHeaderHeight)
    let rightChrome = CGFloat(titledSectionCount) * sectionHeaderHeight
    let rowHeight = max(configuration.rowHeight, Self.fallbackSizingRowHeight)
    let body = max(
      CGFloat(leftRows) * rowHeight,
      CGFloat(rightRows) * rowHeight + rightChrome
    )
    let estimated = max(body, 120)
    return configuration.heightBehavior.resolvedHeight(for: estimated)
  }

  /// Writes through to `super` so ancestor presenters (e.g. anchored dropdown) receive ``preferredContentSizeDidChange(forChildContentContainer:)``.
  private func publishPreferredContentSizeUpdate() {
    let height = resolvedPreferredContentHeight()
    if lastPublishedPreferredHeight == height { return }
    lastPublishedPreferredHeight = height
    super.preferredContentSize = CGSize(width: 0, height: height)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    leftTable.dataSource = self
    leftTable.delegate = self
    leftTable.separatorStyle = .none
    leftTable.translatesAutoresizingMaskIntoConstraints = false
    leftTable.backgroundColor = configuration.leftBackgroundColor
    leftTable.rowHeight = max(configuration.rowHeight, Self.fallbackSizingRowHeight)
    view.addSubview(leftTable)

    rightTable.dataSource = self
    rightTable.delegate = self
    rightTable.separatorInset = configuration.rightSeparatorInset
    rightTable.translatesAutoresizingMaskIntoConstraints = false
    rightTable.backgroundColor = configuration.rightBackgroundColor
    rightTable.rowHeight = max(configuration.rowHeight, Self.fallbackSizingRowHeight)
    view.addSubview(rightTable)

    NSLayoutConstraint.activate([
      leftTable.topAnchor.constraint(equalTo: view.topAnchor),
      leftTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      leftTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      leftTable.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: configuration.leftColumnWidthRatio),

      rightTable.topAnchor.constraint(equalTo: view.topAnchor),
      rightTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      rightTable.leadingAnchor.constraint(equalTo: leftTable.trailingAnchor),
      rightTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private var selectedCategoryID: FKFilterID? {
    model.categories.first(where: { $0.isSelected })?.id
  }

  private func rightSections() -> [FKFilterSection] {
    guard let id = selectedCategoryID else { return [] }
    return model.sectionsByCategoryID[id] ?? []
  }

  private func section(at index: Int) -> FKFilterSection? {
    let sections = rightSections()
    guard sections.indices.contains(index) else { return nil }
    return sections[index]
  }
}

extension FKFilterTwoColumnListViewController: UITableViewDataSource, UITableViewDelegate {
  public func numberOfSections(in tableView: UITableView) -> Int {
    if tableView === leftTable { return 1 }
    return rightSections().count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView === leftTable { return model.categories.count }
    return rightSections()[section].items.count
  }

  public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard tableView === rightTable, configuration.allowsSelectingSectionHeader == false else { return nil }
    return rightSections()[section].title
  }

  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    guard tableView === rightTable else { return 0 }
    guard let modelSection = self.section(at: section), let title = modelSection.title, title.isEmpty == false else {
      return 0
    }
    return max(configuration.sectionHeaderHeight, Self.fallbackSizingSectionHeaderHeight)
  }

  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard tableView === rightTable else { return nil }
    guard let modelSection = self.section(at: section), let title = modelSection.title, title.isEmpty == false else {
      return nil
    }
    guard configuration.allowsSelectingSectionHeader else { return nil }

    let header = UIControl()
    header.backgroundColor = configuration.rightBackgroundColor
    header.tag = section
    header.addAction(UIAction(handler: { [weak self] _ in
      self?.handleRightHeaderTap(sectionIndex: section)
    }), for: .touchUpInside)

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = title
    label.numberOfLines = 2
    label.adjustsFontForContentSizeCategory = true
    label.font = configuration.rightSectionHeaderStyle.font
    label.textColor = (selectedHeaderSectionID == modelSection.id)
      ? configuration.rightSectionHeaderStyle.selectedTextColor
      : configuration.rightSectionHeaderStyle.normalTextColor
    header.addSubview(label)

    let insets = configuration.rightSectionHeaderStyle.contentInsets
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: header.topAnchor, constant: insets.top),
      label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: insets.left),
      label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -insets.right),
      label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -insets.bottom),
      header.heightAnchor.constraint(greaterThanOrEqualToConstant: configuration.rightSectionHeaderStyle.minimumHeight),
    ])
    return header
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

    if tableView === leftTable {
      let cat = model.categories[indexPath.row]
      if let configureLeftCell = configuration.configureLeftCell {
        configureLeftCell(cell, indexPath, cat)
        return cell
      }

      cell.textLabel?.text = cat.title
      cell.detailTextLabel?.text = nil
      cell.textLabel?.font = configuration.leftCellStyle.font
      cell.textLabel?.textAlignment = configuration.leftCellStyle.textAlignment
      cell.textLabel?.textColor = cat.isSelected ? configuration.leftCellStyle.selectedTextColor : configuration.leftCellStyle.normalTextColor
      cell.backgroundColor = cat.isSelected
        ? (configuration.leftCellStyle.selectedRowBackgroundColor ?? configuration.leftCellStyle.rowBackgroundColor)
        : configuration.leftCellStyle.rowBackgroundColor
      cell.selectionStyle = .none
      return cell
    }

    let section = rightSections()[indexPath.section]
    let item = section.items[indexPath.row]
    if let configureRightCell = configuration.configureRightCell {
      configureRightCell(cell, indexPath, item, section)
      return cell
    }

    if let attributedTitle = item.attributedTitle {
      cell.textLabel?.attributedText = NSAttributedString(attributedTitle)
    } else {
      cell.textLabel?.attributedText = nil
      cell.textLabel?.text = item.title
    }
    cell.textLabel?.font = configuration.rightCellStyle.font
    cell.textLabel?.textAlignment = configuration.rightCellStyle.textAlignment
    if let attributedSubtitle = item.attributedSubtitle {
      cell.detailTextLabel?.attributedText = NSAttributedString(attributedSubtitle)
    } else {
      cell.detailTextLabel?.attributedText = nil
      cell.detailTextLabel?.text = item.subtitle
      cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
      cell.detailTextLabel?.textColor = .secondaryLabel
    }
    if !item.isEnabled {
      cell.textLabel?.textColor = configuration.rightCellStyle.disabledTextColor
      if item.attributedSubtitle == nil {
        cell.detailTextLabel?.textColor = .tertiaryLabel
      }
    } else if item.isSelected {
      cell.textLabel?.textColor = configuration.rightCellStyle.selectedTextColor
    } else {
      cell.textLabel?.textColor = configuration.rightCellStyle.normalTextColor
    }
    cell.backgroundColor = configuration.rightCellStyle.rowBackgroundColor
    cell.isUserInteractionEnabled = item.isEnabled
    cell.accessoryType = .none
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if tableView === leftTable {
      tableView.deselectRow(at: indexPath, animated: false)
      let selectedCategory = model.categories[indexPath.row]
      let tappedID = selectedCategory.id
      for i in model.categories.indices {
        model.categories[i].isSelected = (model.categories[i].id == tappedID)
      }
      selectedHeaderSectionID = nil
      onChange(model)
      let sections = model.sectionsByCategoryID[tappedID] ?? []
      if sections.isEmpty {
        let item = FKFilterOptionItem(id: selectedCategory.id, title: selectedCategory.title, isSelected: true)
        onSelection?(.init(sectionID: nil, item: item, effectiveSelectionMode: .single))
      }
      UIView.performWithoutAnimation {
        leftTable.reloadData()
        rightTable.reloadData()
        publishPreferredContentSizeUpdate()
      }
      return
    }

    tableView.deselectRow(at: indexPath, animated: true)

    guard let catID = selectedCategoryID else { return }
    var sections = model.sectionsByCategoryID[catID] ?? []
    var sec = sections[indexPath.section]
    let tapped = sec.items[indexPath.row]
    let tappedItemID = tapped.id
    selectedHeaderSectionID = nil

    let effectiveMode = FKFilterSelectionMode.effective(
      requested: sec.selectionMode,
      allowsMultipleFromTab: allowsMultipleSelection
    )

    switch effectiveMode {
    case .single:
      switch configuration.singleSelectionScope {
      case .withinSection:
        for i in sec.items.indices {
          sec.items[i].isSelected = (sec.items[i].id == tappedItemID)
        }
      case .globalAcrossSections:
        for sIdx in sections.indices {
          for i in sections[sIdx].items.indices {
            let isCurrent = (sIdx == indexPath.section) && (sections[sIdx].items[i].id == tappedItemID)
            sections[sIdx].items[i].isSelected = isCurrent
          }
        }
      }
    case .multiple:
      for i in sec.items.indices where sec.items[i].id == tappedItemID {
        sec.items[i].isSelected.toggle()
      }
    }

    if configuration.singleSelectionScope == .withinSection || effectiveMode == .multiple {
      sections[indexPath.section] = sec
    }
    model.sectionsByCategoryID[catID] = sections
    if effectiveMode == .single, configuration.singleSelectionScope == .globalAcrossSections {
      rightTable.reloadData()
    } else {
      rightTable.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    }
    onChange(model)
    onSelection?(.init(sectionID: sec.id, item: tapped, effectiveSelectionMode: effectiveMode))
  }

  private func handleRightHeaderTap(sectionIndex: Int) {
    guard configuration.allowsSelectingSectionHeader else { return }
    guard let catID = selectedCategoryID else { return }
    guard var sections = model.sectionsByCategoryID[catID] else { return }
    guard sections.indices.contains(sectionIndex) else { return }

    let target = sections[sectionIndex]
    selectedHeaderSectionID = target.id

    // Header selection has priority in this mode: clear all row selections.
    for sIdx in sections.indices {
      for i in sections[sIdx].items.indices {
        sections[sIdx].items[i].isSelected = false
      }
    }
    model.sectionsByCategoryID[catID] = sections
    rightTable.reloadData()
    onChange(model)

    let title = target.title ?? ""
    let headerItem = FKFilterOptionItem(id: target.id, title: title, isSelected: true)
    onSelection?(.init(sectionID: target.id, item: headerItem, effectiveSelectionMode: .single))
  }
}

