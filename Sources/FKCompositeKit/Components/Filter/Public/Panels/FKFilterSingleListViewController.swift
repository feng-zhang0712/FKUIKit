import UIKit

/// Panel controller that renders a single `FKFilterSection` as a vertical list (`UITableView`).
///
/// Typical use cases:
/// - Sort order (最新/最热/好评)
/// - Simple single-select or multi-select option lists
///
/// Key behaviors:
/// - Selection updates the in-memory model and calls `onChange`
/// - Also forwards a concise selection event via `onSelection` (used by ``FKFilterPanelFactory`` / ``FKFilterController``)
/// - Height is controlled by `Configuration.heightBehavior` (auto/capped/fixed/ratio)
public final class FKFilterSingleListViewController: UITableViewController {
  public typealias CellContentConfiguration = (
    _ cell: UITableViewCell,
    _ indexPath: IndexPath,
    _ item: FKFilterOptionItem,
    _ section: FKFilterSection
  ) -> Void

  public struct Configuration {
    public var rowHeight: CGFloat
    public var separatorInset: UIEdgeInsets
    public var showsFooter: Bool
    public var cellStyle: FKFilterListCellStyle
    public var heightBehavior: FKFilterPanelHeightBehavior
    /// Optional hook for per-cell customization.
    /// Called after the default content/style has been applied.
    public var configureCell: CellContentConfiguration?

    public init(
      rowHeight: CGFloat = 44,
      separatorInset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16),
      showsFooter: Bool = false,
      cellStyle: FKFilterListCellStyle = .init(),
      heightBehavior: FKFilterPanelHeightBehavior = .automatic(minimum: 44),
      configureCell: CellContentConfiguration? = nil
    ) {
      self.rowHeight = rowHeight
      self.separatorInset = separatorInset
      self.showsFooter = showsFooter
      self.cellStyle = cellStyle
      self.heightBehavior = heightBehavior
      self.configureCell = configureCell
    }
  }

  private var section: FKFilterSection
  private let configuration: Configuration
  private let onChange: (FKFilterSection) -> Void
  private let onSelection: ((FKFilterPanelSelection) -> Void)?
  private let allowsMultipleSelection: Bool

  /// Row height used for `FKPresentation` sizing before the table has a real layout pass.
  private static let fallbackSizingRowHeight: CGFloat = 44

  public init(
    section: FKFilterSection,
    configuration: Configuration = .init(),
    onChange: @escaping (FKFilterSection) -> Void,
    onSelection: ((FKFilterPanelSelection) -> Void)? = nil,
    allowsMultipleSelection: Bool = false
  ) {
    self.section = section
    self.configuration = configuration
    self.onChange = onChange
    self.onSelection = onSelection
    self.allowsMultipleSelection = allowsMultipleSelection
    super.init(style: .plain)
  }

  public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public override var preferredContentSize: CGSize {
    get {
      let rowHeight = max(configuration.rowHeight, Self.fallbackSizingRowHeight)
      let estimated = CGFloat(section.items.count) * rowHeight
      let h = configuration.heightBehavior.resolvedHeight(for: estimated)
      return CGSize(width: 0, height: h)
    }
    set { super.preferredContentSize = newValue }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    tableView.rowHeight = max(configuration.rowHeight, Self.fallbackSizingRowHeight)
    tableView.separatorInset = configuration.separatorInset
    tableView.tableFooterView = configuration.showsFooter ? nil : UIView()
    tableView.backgroundColor = .systemBackground
  }

  public override func numberOfSections(in tableView: UITableView) -> Int { 1 }
  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.section.items.count }

  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = section.items[indexPath.row]
    let hasSubtitleContent =
      (item.subtitle.map { !$0.isEmpty } ?? false) || item.attributedSubtitle != nil
    let cell = UITableViewCell(style: hasSubtitleContent ? .subtitle : .default, reuseIdentifier: nil)
    if let configureCell = configuration.configureCell {
      configureCell(cell, indexPath, item, section)
      return cell
    }

    if let attributedTitle = item.attributedTitle {
      cell.textLabel?.attributedText = NSAttributedString(attributedTitle)
    } else {
      cell.textLabel?.attributedText = nil
      cell.textLabel?.text = item.title
    }
    cell.textLabel?.textAlignment = configuration.cellStyle.textAlignment
    cell.textLabel?.font = configuration.cellStyle.font
    if let attributedSubtitle = item.attributedSubtitle {
      cell.detailTextLabel?.attributedText = NSAttributedString(attributedSubtitle)
    } else {
      cell.detailTextLabel?.attributedText = nil
      cell.detailTextLabel?.text = item.subtitle
      cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
      cell.detailTextLabel?.textColor = .secondaryLabel
    }
    cell.detailTextLabel?.textAlignment = configuration.cellStyle.textAlignment
    if !item.isEnabled {
      cell.textLabel?.textColor = configuration.cellStyle.disabledTextColor
      if item.attributedSubtitle == nil {
        cell.detailTextLabel?.textColor = .tertiaryLabel
      }
    } else if item.isSelected {
      cell.textLabel?.textColor = configuration.cellStyle.selectedTextColor
    } else {
      cell.textLabel?.textColor = configuration.cellStyle.normalTextColor
    }
    cell.backgroundColor = item.isSelected ? (configuration.cellStyle.selectedRowBackgroundColor ?? configuration.cellStyle.rowBackgroundColor) : configuration.cellStyle.rowBackgroundColor
    cell.selectionStyle = .default
    cell.isUserInteractionEnabled = item.isEnabled
    cell.accessoryType = .none
    return cell
  }

  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let tapped = section.items[indexPath.row]
    let tappedID = tapped.id

    let effectiveMode = FKFilterSelectionMode.effective(
      requested: section.selectionMode,
      allowsMultipleFromTab: allowsMultipleSelection
    )

    switch effectiveMode {
    case .single:
      for i in section.items.indices {
        section.items[i].isSelected = (section.items[i].id == tappedID)
      }
    case .multiple:
      for i in section.items.indices where section.items[i].id == tappedID {
        section.items[i].isSelected.toggle()
      }
    }

    tableView.reloadData()
    onChange(section)
    onSelection?(.init(sectionID: section.id, item: tapped, effectiveSelectionMode: effectiveMode))
  }
}

