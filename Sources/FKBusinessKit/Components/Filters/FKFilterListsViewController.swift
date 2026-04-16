import UIKit

public final class FKFilterSingleListViewController: UITableViewController {
  private var section: FKFilterSection
  private let onChange: (FKFilterSection) -> Void
  private let onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)?
  private let allowsMultipleSelection: Bool
  private let centerText: Bool

  /// Row height used for `FKPresentation` sizing before the table has a real layout pass.
  private static let sizingRowHeight: CGFloat = 44

  public init(
    section: FKFilterSection,
    onChange: @escaping (FKFilterSection) -> Void,
    onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)? = nil,
    allowsMultipleSelection: Bool = false,
    centerText: Bool = false
  ) {
    self.section = section
    self.onChange = onChange
    self.onSelectItem = onSelectItem
    self.allowsMultipleSelection = allowsMultipleSelection
    self.centerText = centerText
    super.init(style: .plain)
  }

  public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public override var preferredContentSize: CGSize {
    get {
      let h = CGFloat(section.items.count) * Self.sizingRowHeight
      return CGSize(width: 0, height: max(h, Self.sizingRowHeight))
    }
    set { super.preferredContentSize = newValue }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    tableView.rowHeight = Self.sizingRowHeight
    tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
    tableView.tableFooterView = UIView()
    tableView.backgroundColor = .systemBackground
  }

  public override func numberOfSections(in tableView: UITableView) -> Int { 1 }
  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.section.items.count }

  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let item = section.items[indexPath.row]
    cell.textLabel?.text = item.title
    cell.textLabel?.textAlignment = centerText ? .center : .natural
    cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
    if !item.isEnabled {
      cell.textLabel?.textColor = .secondaryLabel
    } else if item.isSelected {
      cell.textLabel?.textColor = .systemRed
    } else {
      cell.textLabel?.textColor = .label
    }
    cell.selectionStyle = .default
    cell.isUserInteractionEnabled = item.isEnabled
    cell.accessoryType = .none
    return cell
  }

  public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let tapped = section.items[indexPath.row]
    let tappedID = tapped.id

    let effectiveMode: FKFilterSelectionMode = (allowsMultipleSelection && section.selectionMode == .multiple) ? .multiple : .single

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
    onSelectItem?(section.id, tapped, effectiveMode)
  }
}

public final class FKFilterTwoColumnViewController: UIViewController {
  private var model: FKFilterTwoColumnModel
  private let onChange: (FKFilterTwoColumnModel) -> Void
  private let onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)?
  private let allowsMultipleSelection: Bool

  private let leftTable = UITableView(frame: .zero, style: .plain)
  private let rightTable = UITableView(frame: .zero, style: .plain)

  private static let sizingRowHeight: CGFloat = 44
  private static let sizingSectionHeaderHeight: CGFloat = 28

  public init(
    model: FKFilterTwoColumnModel,
    onChange: @escaping (FKFilterTwoColumnModel) -> Void,
    onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)? = nil,
    allowsMultipleSelection: Bool = false
  ) {
    self.model = model
    self.onChange = onChange
    self.onSelectItem = onSelectItem
    self.allowsMultipleSelection = allowsMultipleSelection
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public override var preferredContentSize: CGSize {
    get {
      let leftRows = model.categories.count
      let sections = rightSections()
      let rightRows = sections.reduce(0) { partial, sec in partial + sec.items.count }
      let titledSectionCount = sections.filter { ($0.title ?? "").isEmpty == false }.count
      let rightChrome = CGFloat(titledSectionCount) * Self.sizingSectionHeaderHeight
      let body = max(
        CGFloat(leftRows) * Self.sizingRowHeight,
        CGFloat(rightRows) * Self.sizingRowHeight + rightChrome
      )
      return CGSize(width: 0, height: max(body, 120))
    }
    set { super.preferredContentSize = newValue }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    leftTable.dataSource = self
    leftTable.delegate = self
    leftTable.separatorStyle = .none
    leftTable.translatesAutoresizingMaskIntoConstraints = false
    leftTable.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.6)
    leftTable.rowHeight = Self.sizingRowHeight
    view.addSubview(leftTable)
    
    
    rightTable.dataSource = self
    rightTable.delegate = self
    rightTable.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
    rightTable.translatesAutoresizingMaskIntoConstraints = false
    rightTable.backgroundColor = .systemBackground
    rightTable.rowHeight = Self.sizingRowHeight
    view.addSubview(rightTable)

    NSLayoutConstraint.activate([
      leftTable.topAnchor.constraint(equalTo: view.topAnchor),
      leftTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      leftTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      leftTable.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.30),

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
}

extension FKFilterTwoColumnViewController: UITableViewDataSource, UITableViewDelegate {
  public func numberOfSections(in tableView: UITableView) -> Int {
    if tableView === leftTable { return 1 }
    return rightSections().count
  }

  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView === leftTable { return model.categories.count }
    return rightSections()[section].items.count
  }

  public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard tableView === rightTable else { return nil }
    return rightSections()[section].title
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

    if tableView === leftTable {
      let cat = model.categories[indexPath.row]
      cell.textLabel?.text = cat.title
      cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
      cell.textLabel?.textColor = cat.isSelected ? .systemRed : .label
      cell.backgroundColor = cat.isSelected ? .systemBackground : UIColor.systemGray6.withAlphaComponent(0.6)
      cell.selectionStyle = .none
      return cell
    }

    let section = rightSections()[indexPath.section]
    let item = section.items[indexPath.row]
    cell.textLabel?.text = item.title
    cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
    if !item.isEnabled {
      cell.textLabel?.textColor = .secondaryLabel
    } else if item.isSelected {
      cell.textLabel?.textColor = .systemRed
    } else {
      cell.textLabel?.textColor = .label
    }
    cell.isUserInteractionEnabled = item.isEnabled
    cell.accessoryType = .none
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    if tableView === leftTable {
      let selectedCategory = model.categories[indexPath.row]
      let tappedID = selectedCategory.id
      for i in model.categories.indices {
        model.categories[i].isSelected = (model.categories[i].id == tappedID)
      }
      leftTable.reloadData()
      rightTable.reloadData()
      onChange(model)
      let sections = model.sectionsByCategoryID[tappedID] ?? []
      if sections.isEmpty {
        let item = FKFilterOptionItem(id: selectedCategory.id, title: selectedCategory.title, isSelected: true)
        onSelectItem?(nil, item, .single)
      }
      return
    }

    guard let catID = selectedCategoryID else { return }
    var sections = model.sectionsByCategoryID[catID] ?? []
    var sec = sections[indexPath.section]
    let tapped = sec.items[indexPath.row]
    let tappedItemID = tapped.id

    let effectiveMode: FKFilterSelectionMode = (allowsMultipleSelection && sec.selectionMode == .multiple) ? .multiple : .single

    switch effectiveMode {
    case .single:
      for i in sec.items.indices {
        sec.items[i].isSelected = (sec.items[i].id == tappedItemID)
      }
    case .multiple:
      for i in sec.items.indices where sec.items[i].id == tappedItemID {
        sec.items[i].isSelected.toggle()
      }
    }

    sections[indexPath.section] = sec
    model.sectionsByCategoryID[catID] = sections
    rightTable.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    onChange(model)
    onSelectItem?(sec.id, tapped, effectiveMode)
  }
}

