//
// FKExpandableTextTableExampleViewController.swift
//
// UITableView demo for FKExpandableText with state cache and dynamic height.
//

import FKUIKit
import UIKit

/// Demonstrates reusable table cells with expandable text.
///
/// Covered scenarios:
/// - Expandable text in UITableViewCell
/// - Reuse-safe state cache
/// - Expand state callback with animated height updates
/// - Manual per-row style customization
final class FKExpandableTextTableExampleViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var items: [DemoItem] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table Expandable Text"
    view.backgroundColor = .systemBackground
    items = Self.makeItems()
    setupTableView()
  }

  private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FKExpandableTextTableCell.self, forCellReuseIdentifier: FKExpandableTextTableCell.reuseID)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.estimatedRowHeight = 150
    tableView.rowHeight = UITableView.automaticDimension
    tableView.separatorStyle = .none
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}

// MARK: - UITableViewDataSource

extension FKExpandableTextTableExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: FKExpandableTextTableCell.reuseID,
      for: indexPath
    ) as? FKExpandableTextTableCell else {
      return UITableViewCell()
    }

    let item = items[indexPath.row]
    cell.render(item: item)

    // Bind stable key to restore expand state after reuse.
    cell.fk_bindExpandableText(cell.expandableText, key: item.id, defaultExpanded: false)
    cell.expandableText.setText(item.content, stateIdentifier: item.id)

    // Re-layout table smoothly when expand state changes.
    cell.expandableText.onStateChange = { [weak tableView] _ in
      UIView.performWithoutAnimation {
        tableView?.beginUpdates()
        tableView?.endUpdates()
      }
    }
    return cell
  }
}

// MARK: - UITableViewDelegate

extension FKExpandableTextTableExampleViewController: UITableViewDelegate {}

// MARK: - Demo Cell

private final class FKExpandableTextTableCell: UITableViewCell {
  static let reuseID = "FKExpandableTextTableCell"

  let titleLabel = UILabel()
  let expandableText = FKExpandableText()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    expandableText.onStateChange = nil
  }

  func render(item: FKExpandableTextTableExampleViewController.DemoItem) {
    titleLabel.text = item.title
    expandableText.configure {
      $0.behavior.collapsedNumberOfLines = 3
      $0.behavior.triggerMode = .all
      $0.textStyle.font = .systemFont(ofSize: 15)
      $0.textStyle.lineSpacing = 5
      $0.textStyle.color = .label
      $0.buttonStyle.expandTitle = "Read More"
      $0.buttonStyle.collapseTitle = "Collapse"
      $0.buttonStyle.titleColor = .systemBlue
      $0.layoutStyle.animationDuration = 0.25
      $0.layoutStyle.buttonPosition = .bottomTrailing
    }
  }

  private func setupViews() {
    selectionStyle = .none
    contentView.backgroundColor = .clear

    let card = UIView()
    card.translatesAutoresizingMaskIntoConstraints = false
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    contentView.addSubview(card)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .label

    expandableText.translatesAutoresizingMaskIntoConstraints = false

    card.addSubview(titleLabel)
    card.addSubview(expandableText)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

      expandableText.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      expandableText.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
      expandableText.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
      expandableText.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
    ])
  }
}

fileprivate extension FKExpandableTextTableExampleViewController {
  struct DemoItem {
    let id: String
    let title: String
    let content: String
  }

  static func makeItems() -> [DemoItem] {
    (1...25).map { index in
      DemoItem(
        id: "table_demo_\(index)",
        title: "Post #\(index)",
        content: """
        This is a long text demo for table cell #\(index). FKExpandableText keeps expand state stable in reusable lists when you bind a stable identifier.
        It also supports smooth animations and dynamic height updates without UI glitches.
        """
      )
    }
  }
}
