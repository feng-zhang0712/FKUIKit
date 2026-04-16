import UIKit

public final class FKFilterCourseTwoColumnViewController: UIViewController {
  private var model: FKFilterTwoColumnModel
  private let onChange: (FKFilterTwoColumnModel) -> Void
  private let onSelectItem: ((FKFilterID?, FKFilterOptionItem, FKFilterSelectionMode) -> Void)?
  private let allowsMultipleSelection: Bool

  private let leftTable = UITableView(frame: .zero, style: .plain)
  private let rightScroll = UIScrollView()
  private let rightStack = UIStackView()

  /// When set, the titled section row (e.g. 政治能力提升) is the active selection; chip selections are cleared.
  private var selectedHeaderSectionID: FKFilterID?

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
    get { CGSize(width: 0, height: 440) }
    set { super.preferredContentSize = newValue }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    leftTable.dataSource = self
    leftTable.delegate = self
    leftTable.separatorStyle = .none
    leftTable.rowHeight = 46
    leftTable.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.6)
    leftTable.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(leftTable)

    rightScroll.translatesAutoresizingMaskIntoConstraints = false
    rightScroll.backgroundColor = .systemBackground
    view.addSubview(rightScroll)

    rightStack.axis = .vertical
    rightStack.spacing = 14
    rightStack.translatesAutoresizingMaskIntoConstraints = false
    rightScroll.addSubview(rightStack)

    NSLayoutConstraint.activate([
      leftTable.topAnchor.constraint(equalTo: view.topAnchor),
      leftTable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      leftTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      leftTable.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.30),

      rightScroll.topAnchor.constraint(equalTo: view.topAnchor),
      rightScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      rightScroll.leadingAnchor.constraint(equalTo: leftTable.trailingAnchor),
      rightScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      rightStack.topAnchor.constraint(equalTo: rightScroll.contentLayoutGuide.topAnchor, constant: 12),
      rightStack.leadingAnchor.constraint(equalTo: rightScroll.contentLayoutGuide.leadingAnchor, constant: 12),
      rightStack.trailingAnchor.constraint(equalTo: rightScroll.contentLayoutGuide.trailingAnchor, constant: -12),
      rightStack.bottomAnchor.constraint(equalTo: rightScroll.contentLayoutGuide.bottomAnchor, constant: -12),
      rightStack.widthAnchor.constraint(equalTo: rightScroll.frameLayoutGuide.widthAnchor, constant: -24),
    ])

    reloadRightContent()
  }

  private var selectedCategoryID: FKFilterID? {
    model.categories.first(where: \.isSelected)?.id
  }

  private func rightSections() -> [FKFilterSection] {
    guard let id = selectedCategoryID else { return [] }
    return model.sectionsByCategoryID[id] ?? []
  }

  private func reloadRightContent() {
    rightStack.arrangedSubviews.forEach { v in
      rightStack.removeArrangedSubview(v)
      v.removeFromSuperview()
    }

    for section in rightSections() {
      let block = makeSectionBlock(section)
      rightStack.addArrangedSubview(block)
    }
  }

  private func makeSectionBlock(_ section: FKFilterSection) -> UIView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 10

    let hasTitle = (section.title ?? "").isEmpty == false
    if hasTitle, let title = section.title {
      let header = makeSectionHeader(title: title, sectionID: section.id)
      container.addArrangedSubview(header)
    }

    guard !section.items.isEmpty else { return container }

    let chipGrid = UIView()
    chipGrid.translatesAutoresizingMaskIntoConstraints = false

    let columnCount = 2
    let chipHeight: CGFloat = 32
    let hSpacing: CGFloat = 10
    let vSpacing: CGFloat = 10
    let rows = Int(ceil(Double(section.items.count) / Double(columnCount)))
    let gridHeight = CGFloat(rows) * chipHeight + CGFloat(max(0, rows - 1)) * vSpacing
    chipGrid.heightAnchor.constraint(equalToConstant: gridHeight).isActive = true

    let scale = max(view.window?.windowScene?.screen.scale ?? view.traitCollection.displayScale, 1)

    for (idx, item) in section.items.enumerated() {
      let row = idx / columnCount
      let col = idx % columnCount

      let button = UIButton(type: .system)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.setTitle(item.title, for: .normal)
      button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
      button.layer.cornerRadius = 6
      button.layer.cornerCurve = .continuous
      button.layer.borderWidth = 1 / scale

      if item.isSelected {
        button.setTitleColor(.systemRed, for: .normal)
        button.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.35).cgColor
      } else {
        button.setTitleColor(.label, for: .normal)
        button.layer.borderColor = UIColor.separator.cgColor
      }

      button.isEnabled = item.isEnabled
      button.addAction(UIAction(handler: { [weak self] _ in
        self?.handleChipTap(sectionID: section.id, index: idx)
      }), for: .touchUpInside)

      chipGrid.addSubview(button)
      NSLayoutConstraint.activate([
        button.topAnchor.constraint(equalTo: chipGrid.topAnchor, constant: CGFloat(row) * (chipHeight + vSpacing)),
        button.heightAnchor.constraint(equalToConstant: chipHeight),
      ])
      if col == 0 {
        NSLayoutConstraint.activate([
          button.leadingAnchor.constraint(equalTo: chipGrid.leadingAnchor),
          button.widthAnchor.constraint(equalTo: chipGrid.widthAnchor, multiplier: 0.5, constant: -hSpacing / 2),
        ])
      } else {
        NSLayoutConstraint.activate([
          button.trailingAnchor.constraint(equalTo: chipGrid.trailingAnchor),
          button.widthAnchor.constraint(equalTo: chipGrid.widthAnchor, multiplier: 0.5, constant: -hSpacing / 2),
        ])
      }
    }

    container.addArrangedSubview(chipGrid)
    return container
  }

  private func makeSectionHeader(title: String, sectionID: FKFilterID) -> UIView {
    let row = UIView()
    row.translatesAutoresizingMaskIntoConstraints = false
    row.accessibilityIdentifier = sectionID.rawValue
    row.backgroundColor = .clear

    let label = UILabel()
    label.text = title
    label.numberOfLines = 2
    label.adjustsFontForContentSizeCategory = true
    let body = UIFont.preferredFont(forTextStyle: .body)
    label.font = UIFont(
      descriptor: body.fontDescriptor.withSymbolicTraits(.traitBold) ?? body.fontDescriptor,
      size: 0
    )
    label.translatesAutoresizingMaskIntoConstraints = false

    let isSelected = selectedHeaderSectionID == sectionID
    label.textColor = isSelected ? .systemRed : .label

    row.addSubview(label)

    NSLayoutConstraint.activate([
      row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      label.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
      label.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(onHeaderTap(_:)))
    row.addGestureRecognizer(tap)
    row.isUserInteractionEnabled = true

    return row
  }

  @objc private func onHeaderTap(_ sender: UITapGestureRecognizer) {
    guard let raw = sender.view?.accessibilityIdentifier else { return }
    let sectionID = FKFilterID(rawValue: raw)
    guard let catID = selectedCategoryID else { return }
    guard var sections = model.sectionsByCategoryID[catID] else { return }
    guard let sec = sections.first(where: { $0.id == sectionID }) else { return }
    let title = sec.title ?? ""

    selectedHeaderSectionID = sectionID
    for si in sections.indices {
      for i in sections[si].items.indices {
        sections[si].items[i].isSelected = false
      }
    }
    model.sectionsByCategoryID[catID] = sections

    onChange(model)
    let item = FKFilterOptionItem(id: sectionID, title: title, isSelected: true)
    onSelectItem?(sectionID, item, .single)
    reloadRightContent()
  }

  private func handleChipTap(sectionID: FKFilterID, index: Int) {
    guard let catID = selectedCategoryID else { return }
    var sections = model.sectionsByCategoryID[catID] ?? []
    guard let sIdx = sections.firstIndex(where: { $0.id == sectionID }) else { return }
    var sec = sections[sIdx]
    guard sec.items.indices.contains(index) else { return }
    let tapped = sec.items[index]

    selectedHeaderSectionID = nil

    let effectiveMode: FKFilterSelectionMode = (allowsMultipleSelection && sec.selectionMode == .multiple) ? .multiple : .single

    switch effectiveMode {
    case .single:
      for si in sections.indices {
        for i in sections[si].items.indices {
          let sel = (sections[si].id == sectionID && i == index)
          sections[si].items[i].isSelected = sel
        }
      }
    case .multiple:
      sec.items[index].isSelected.toggle()
      sections[sIdx] = sec
    }

    model.sectionsByCategoryID[catID] = sections

    onChange(model)
    onSelectItem?(sectionID, tapped, effectiveMode)
    reloadRightContent()
  }
}

extension FKFilterCourseTwoColumnViewController: UITableViewDataSource, UITableViewDelegate {
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    model.categories.count
  }

  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let cat = model.categories[indexPath.row]
    cell.textLabel?.text = cat.title
    cell.textLabel?.font = .preferredFont(forTextStyle: .callout)
    cell.textLabel?.numberOfLines = 1
    cell.textLabel?.lineBreakMode = .byTruncatingTail
    cell.textLabel?.textColor = cat.isSelected ? .systemRed : .label
    cell.selectionStyle = .none
    cell.backgroundColor = cat.isSelected ? .systemBackground : UIColor.systemGray6.withAlphaComponent(0.6)
    return cell
  }

  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let tappedID = model.categories[indexPath.row].id
    for i in model.categories.indices {
      model.categories[i].isSelected = (model.categories[i].id == tappedID)
    }
    leftTable.reloadData()

    selectedHeaderSectionID = nil

    reloadRightContent()
    onChange(model)
  }
}
