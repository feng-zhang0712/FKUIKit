import UIKit

final class FKFilterTwoColumnGridCell: UICollectionViewCell {
  static let reuseID = "FKFilterTwoColumnGridCell"

  private let label = UILabel()
  private var topConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  private var trailingConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.cornerCurve = .continuous
    let scale = max(traitCollection.displayScale, 1)
    contentView.layer.borderWidth = 1 / scale

    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 1
    label.adjustsFontForContentSizeCategory = true
    label.textAlignment = .center
    contentView.addSubview(label)

    topConstraint = label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
    bottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
    leadingConstraint = label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10)
    trailingConstraint = label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
    NSLayoutConstraint.activate([
      topConstraint,
      bottomConstraint,
      leadingConstraint,
      trailingConstraint,
    ].compactMap { $0 })
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func apply(item: FKFilterOptionItem, style: FKFilterPillStyle) {
    label.text = item.title
    label.font = style.font
    contentView.layer.cornerRadius = style.cornerRadius
    topConstraint?.constant = style.contentInsets.top
    bottomConstraint?.constant = -style.contentInsets.bottom
    leadingConstraint?.constant = style.contentInsets.left
    trailingConstraint?.constant = -style.contentInsets.right

    if !item.isEnabled {
      contentView.backgroundColor = style.disabledBackgroundColor
      contentView.layer.borderColor = style.disabledBorderColor.cgColor
      label.textColor = style.disabledTextColor
      contentView.alpha = style.disabledAlpha
      isUserInteractionEnabled = false
      return
    }

    contentView.alpha = 1
    isUserInteractionEnabled = true
    if item.isSelected {
      contentView.backgroundColor = style.selectedBackgroundColor
      contentView.layer.borderColor = style.selectedBorderColor.cgColor
      label.textColor = style.selectedTextColor
    } else {
      contentView.backgroundColor = style.normalBackgroundColor
      contentView.layer.borderColor = style.normalBorderColor.cgColor
      label.textColor = style.normalTextColor
    }
  }
}

final class FKFilterTwoColumnGridHeaderView: UICollectionReusableView {
  static let reuseID = "FKFilterTwoColumnGridHeaderView"

  private let titleLabel = UILabel()
  private var topConstraint: NSLayoutConstraint?
  private var bottomConstraint: NSLayoutConstraint?
  private var leadingConstraint: NSLayoutConstraint?
  private var trailingConstraint: NSLayoutConstraint?
  private var tapAction: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 2
    addSubview(titleLabel)

    topConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10)
    bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    leadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
    trailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
    NSLayoutConstraint.activate([
      topConstraint,
      bottomConstraint,
      leadingConstraint,
      trailingConstraint,
    ].compactMap { $0 })

    let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
    addGestureRecognizer(tap)
    isUserInteractionEnabled = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func apply(
    title: String,
    style: FKFilterTwoColumnGridViewController.Configuration.RightHeaderStyle,
    isSelected: Bool,
    tapAction: (() -> Void)?
  ) {
    titleLabel.text = title
    titleLabel.font = style.font
    titleLabel.textColor = isSelected ? style.selectedTextColor : style.normalTextColor
    topConstraint?.constant = style.contentInsets.top
    bottomConstraint?.constant = -style.contentInsets.bottom
    leadingConstraint?.constant = style.contentInsets.left
    trailingConstraint?.constant = -style.contentInsets.right
    self.tapAction = tapAction
  }

  @objc private func onTap() {
    tapAction?()
  }
}

public final class FKFilterTwoColumnGridViewController: UIViewController {
  public typealias LeftCellContentConfiguration = (
    _ cell: UITableViewCell,
    _ indexPath: IndexPath,
    _ category: FKFilterTwoColumnModel.Category
  ) -> Void

  public typealias ItemCellContentConfiguration = (
    _ cell: UICollectionViewCell,
    _ indexPath: IndexPath,
    _ item: FKFilterOptionItem,
    _ section: FKFilterSection
  ) -> Void

  /// Two-column panel controller: left category list (`UITableView`) + right grid (`UICollectionView`).
  ///
  /// This is the "course-like" layout:
  /// - Right side groups options by `FKFilterSection` and renders items as pill buttons in a grid.
  /// - Section headers can be shown, and optionally become selectable (header tap clears pill selections).
  ///
  /// Use when you want:
  /// - Better density than a table list
  /// - Reusable cells and smooth scrolling for larger datasets
  public enum SingleSelectionScope {
    case withinSection
    case globalAcrossSections
  }

  public struct Configuration {
    public struct RightHeaderStyle {
      public var normalTextColor: UIColor
      public var selectedTextColor: UIColor
      public var font: UIFont
      public var contentInsets: UIEdgeInsets
      public var minimumHeight: CGFloat

      public init(
        normalTextColor: UIColor = .label,
        selectedTextColor: UIColor = .systemRed,
        font: UIFont = {
          let base = UIFont.preferredFont(forTextStyle: .subheadline)
          return UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        }(),
        contentInsets: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8),
        minimumHeight: CGFloat = 36
      ) {
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
        self.font = font
        self.contentInsets = contentInsets
        self.minimumHeight = minimumHeight
      }
    }

    public var leftRowHeight: CGFloat
    public var leftColumnWidthRatio: CGFloat
    public var leftCellStyle: FKFilterListCellStyle
    public var rightBackgroundColor: UIColor
    public var rightContentInsets: UIEdgeInsets
    public var rightSectionSpacing: CGFloat
    public var interitemSpacing: CGFloat
    public var lineSpacing: CGFloat
    public var itemHeight: CGFloat
    public var itemColumns: Int
    public var pillStyle: FKFilterPillStyle
    public var rightHeaderStyle: RightHeaderStyle
    public var allowsSelectingSectionHeader: Bool
    public var singleSelectionScope: SingleSelectionScope
    public var heightBehavior: FKFilterPanelHeightBehavior
    /// Optional hook for left table cell customization.
    public var configureLeftCell: LeftCellContentConfiguration?
    /// Optional hook for right collection item customization.
    public var configureItemCell: ItemCellContentConfiguration?

    public init(
      leftRowHeight: CGFloat = 46,
      leftColumnWidthRatio: CGFloat = 0.30,
      leftCellStyle: FKFilterListCellStyle = .init(
        rowBackgroundColor: UIColor.systemGray6.withAlphaComponent(0.6),
        selectedRowBackgroundColor: .systemBackground
      ),
      rightBackgroundColor: UIColor = .systemBackground,
      rightContentInsets: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12),
      rightSectionSpacing: CGFloat = 16,
      interitemSpacing: CGFloat = 10,
      lineSpacing: CGFloat = 10,
      itemHeight: CGFloat = 40,
      itemColumns: Int = 2,
      pillStyle: FKFilterPillStyle = .init(cornerRadius: 6, contentInsets: .init(top: 8, left: 10, bottom: 8, right: 10)),
      rightHeaderStyle: RightHeaderStyle = .init(),
      allowsSelectingSectionHeader: Bool = true,
      singleSelectionScope: SingleSelectionScope = .globalAcrossSections,
      heightBehavior: FKFilterPanelHeightBehavior = .automatic(
        minimum: 100,
        screenMinimumFraction: 0.36,
        maximumScreenFraction: 0.88
      ),
      configureLeftCell: LeftCellContentConfiguration? = nil,
      configureItemCell: ItemCellContentConfiguration? = nil
    ) {
      self.leftRowHeight = max(leftRowHeight, 40)
      self.leftColumnWidthRatio = max(0.2, min(leftColumnWidthRatio, 0.6))
      self.leftCellStyle = leftCellStyle
      self.rightBackgroundColor = rightBackgroundColor
      self.rightContentInsets = rightContentInsets
      self.rightSectionSpacing = rightSectionSpacing
      self.interitemSpacing = interitemSpacing
      self.lineSpacing = lineSpacing
      self.itemHeight = max(itemHeight, 28)
      self.itemColumns = max(itemColumns, 1)
      self.pillStyle = pillStyle
      self.rightHeaderStyle = rightHeaderStyle
      self.allowsSelectingSectionHeader = allowsSelectingSectionHeader
      self.singleSelectionScope = singleSelectionScope
      self.heightBehavior = heightBehavior
      self.configureLeftCell = configureLeftCell
      self.configureItemCell = configureItemCell
    }
  }

  private var model: FKFilterTwoColumnModel
  private let configuration: Configuration
  private let onChange: (FKFilterTwoColumnModel) -> Void
  private let onSelection: ((FKFilterPanelSelection) -> Void)?
  private let allowsMultipleSelection: Bool
  private var selectedHeaderSectionID: FKFilterID?

  private let leftTable = UITableView(frame: .zero, style: .plain)
  private lazy var rightCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = configuration.interitemSpacing
    layout.minimumLineSpacing = configuration.lineSpacing
    layout.sectionInset = configuration.rightContentInsets
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.backgroundColor = configuration.rightBackgroundColor
    cv.translatesAutoresizingMaskIntoConstraints = false
    cv.dataSource = self
    cv.delegate = self
    cv.alwaysBounceVertical = true
    cv.register(FKFilterTwoColumnGridCell.self, forCellWithReuseIdentifier: FKFilterTwoColumnGridCell.reuseID)
    cv.register(
      FKFilterTwoColumnGridHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: FKFilterTwoColumnGridHeaderView.reuseID
    )
    return cv
  }()

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

  private func resolvedPreferredContentHeight() -> CGFloat {
    let sections = rightSections()
    let leftBody = CGFloat(model.categories.count) * configuration.leftRowHeight
    let headerCount = sections.filter { ($0.title ?? "").isEmpty == false }.count
    let itemCount = sections.reduce(0) { $0 + $1.items.count }
    let rows = ceil(CGFloat(max(itemCount, 1)) / CGFloat(configuration.itemColumns))
    let rightBody = rows * configuration.itemHeight + max(rows - 1, 0) * configuration.lineSpacing
    let rightHeaders = CGFloat(headerCount) * max(configuration.rightHeaderStyle.minimumHeight, 1)
    let rightInsets = configuration.rightContentInsets.top + configuration.rightContentInsets.bottom + CGFloat(max(sections.count - 1, 0)) * configuration.rightSectionSpacing
    let estimated = max(leftBody, rightBody + rightHeaders + rightInsets)
    return configuration.heightBehavior.resolvedHeight(for: max(estimated, 140))
  }

  private func publishPreferredContentSizeUpdate() {
    super.preferredContentSize = CGSize(width: 0, height: resolvedPreferredContentHeight())
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    leftTable.dataSource = self
    leftTable.delegate = self
    leftTable.separatorStyle = .none
    leftTable.rowHeight = configuration.leftRowHeight
    leftTable.backgroundColor = configuration.leftCellStyle.rowBackgroundColor
    leftTable.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(leftTable)
    view.addSubview(rightCollectionView)
    NSLayoutConstraint.activate([
      leftTable.topAnchor.constraint(equalTo: view.topAnchor),
      leftTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      leftTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      leftTable.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: configuration.leftColumnWidthRatio),

      rightCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
      rightCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      rightCollectionView.leadingAnchor.constraint(equalTo: leftTable.trailingAnchor),
      rightCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  private var selectedCategoryID: FKFilterID? {
    model.categories.first(where: \.isSelected)?.id
  }

  private func rightSections() -> [FKFilterSection] {
    guard let selectedCategoryID else { return [] }
    return model.sectionsByCategoryID[selectedCategoryID] ?? []
  }

  private func handleHeaderTap(sectionIndex: Int) {
    guard configuration.allowsSelectingSectionHeader else { return }
    guard let catID = selectedCategoryID else { return }
    var sections = model.sectionsByCategoryID[catID] ?? []
    guard sections.indices.contains(sectionIndex) else { return }
    let target = sections[sectionIndex]
    selectedHeaderSectionID = target.id
    for sIdx in sections.indices {
      for i in sections[sIdx].items.indices {
        sections[sIdx].items[i].isSelected = false
      }
    }
    model.sectionsByCategoryID[catID] = sections
    rightCollectionView.reloadData()
    onChange(model)
    onSelection?(
      .init(
        sectionID: target.id,
        item: FKFilterOptionItem(id: target.id, title: target.title ?? "", isSelected: true),
        effectiveSelectionMode: .single
      )
    )
  }

  private func handleItemSelection(at indexPath: IndexPath) {
    guard let catID = selectedCategoryID else { return }
    var sections = model.sectionsByCategoryID[catID] ?? []
    guard sections.indices.contains(indexPath.section) else { return }
    var section = sections[indexPath.section]
    guard section.items.indices.contains(indexPath.item) else { return }
    let tapped = section.items[indexPath.item]
    let tappedID = tapped.id
    selectedHeaderSectionID = nil

    let effectiveMode = FKFilterSelectionMode.effective(
      requested: section.selectionMode,
      allowsMultipleFromTab: allowsMultipleSelection
    )

    switch effectiveMode {
    case .single:
      switch configuration.singleSelectionScope {
      case .withinSection:
        for i in section.items.indices {
          section.items[i].isSelected = (section.items[i].id == tappedID)
        }
        sections[indexPath.section] = section
      case .globalAcrossSections:
        for sIdx in sections.indices {
          for i in sections[sIdx].items.indices {
            let isCurrent = (sIdx == indexPath.section) && (sections[sIdx].items[i].id == tappedID)
            sections[sIdx].items[i].isSelected = isCurrent
          }
        }
      }
    case .multiple:
      for i in section.items.indices where section.items[i].id == tappedID {
        section.items[i].isSelected.toggle()
      }
      sections[indexPath.section] = section
    }

    model.sectionsByCategoryID[catID] = sections
    rightCollectionView.reloadData()
    onChange(model)
    onSelection?(.init(sectionID: section.id, item: tapped, effectiveSelectionMode: effectiveMode))
  }
}

extension FKFilterTwoColumnGridViewController: UITableViewDataSource, UITableViewDelegate {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    model.categories.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    let category = model.categories[indexPath.row]
    if let configureLeftCell = configuration.configureLeftCell {
      configureLeftCell(cell, indexPath, category)
      return cell
    }

    cell.textLabel?.text = category.title
    cell.textLabel?.font = configuration.leftCellStyle.font
    cell.textLabel?.textAlignment = configuration.leftCellStyle.textAlignment
    cell.textLabel?.textColor = category.isSelected ? configuration.leftCellStyle.selectedTextColor : configuration.leftCellStyle.normalTextColor
    cell.selectionStyle = .none
    cell.backgroundColor = category.isSelected
      ? (configuration.leftCellStyle.selectedRowBackgroundColor ?? configuration.leftCellStyle.rowBackgroundColor)
      : configuration.leftCellStyle.rowBackgroundColor
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let tappedID = model.categories[indexPath.row].id
    for i in model.categories.indices {
      model.categories[i].isSelected = (model.categories[i].id == tappedID)
    }
    selectedHeaderSectionID = nil
    leftTable.reloadData()
    rightCollectionView.reloadData()
    onChange(model)
    publishPreferredContentSizeUpdate()
  }
}

extension FKFilterTwoColumnGridViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    rightSections().count
  }

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    rightSections()[section].items.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKFilterTwoColumnGridCell.reuseID, for: indexPath)
    guard let gridCell = cell as? FKFilterTwoColumnGridCell else { return cell }
    let section = rightSections()[indexPath.section]
    let item = section.items[indexPath.item]
    if let configureItemCell = configuration.configureItemCell {
      configureItemCell(gridCell, indexPath, item, section)
      return gridCell
    }

    gridCell.apply(item: item, style: configuration.pillStyle)
    return gridCell
  }

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    handleItemSelection(at: indexPath)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let insets = configuration.rightContentInsets
    let width = collectionView.bounds.width - insets.left - insets.right
    let columns = CGFloat(configuration.itemColumns)
    let spacing = configuration.interitemSpacing * max(columns - 1, 0)
    let itemW = floor((width - spacing) / columns)
    return CGSize(width: max(itemW, 44), height: configuration.itemHeight)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    var insets = configuration.rightContentInsets
    insets.top = section == 0 ? configuration.rightContentInsets.top : configuration.rightSectionSpacing
    return insets
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    referenceSizeForHeaderInSection section: Int
  ) -> CGSize {
    let modelSection = rightSections()[section]
    guard let title = modelSection.title, !title.isEmpty else { return .zero }
    return CGSize(width: collectionView.bounds.width, height: configuration.rightHeaderStyle.minimumHeight)
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    guard kind == UICollectionView.elementKindSectionHeader else {
      return UICollectionReusableView()
    }
    let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: FKFilterTwoColumnGridHeaderView.reuseID,
      for: indexPath
    )
    guard
      let header = view as? FKFilterTwoColumnGridHeaderView
    else {
      return view
    }
    let section = rightSections()[indexPath.section]
    let title = section.title ?? ""
    let isSelected = selectedHeaderSectionID == section.id
    let tapHandler: (() -> Void)? = configuration.allowsSelectingSectionHeader ? { [weak self] in
      self?.handleHeaderTap(sectionIndex: indexPath.section)
    } : nil
    header.apply(
      title: title,
      style: configuration.rightHeaderStyle,
      isSelected: isSelected,
      tapAction: tapHandler
    )
    return header
  }
}

