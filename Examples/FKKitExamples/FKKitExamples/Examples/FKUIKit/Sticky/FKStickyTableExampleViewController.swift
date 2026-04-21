//
// FKStickyTableExampleViewController.swift
//

import FKUIKit
import UIKit

/// Demonstrates sticky behavior for grouped table section headers.
final class FKStickyTableExampleViewController: UITableViewController {
  private let sections = Array(0..<8)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table Sticky Header"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.sectionHeaderHeight = 52
    tableView.rowHeight = 56

    var configuration = FKStickyConfiguration.default
    configuration.additionalTopInset = 4
    tableView.fk_stickyEngine.apply(configuration: configuration)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    reloadStickyTargets()
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    6
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = "Section \(indexPath.section) Row \(indexPath.row)"
    config.secondaryText = "Native grouped header + FKSticky"
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    return cell
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let header = UIView()
    header.backgroundColor = .tertiarySystemBackground
    let label = UILabel(frame: .init(x: 16, y: 0, width: tableView.bounds.width - 32, height: 52))
    label.text = "Section Header \(section)"
    label.font = .boldSystemFont(ofSize: 16)
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    header.addSubview(label)
    return header
  }

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollView.fk_handleStickyScroll()
  }

  private func reloadStickyTargets() {
    let targets: [FKStickyTarget] = sections.compactMap { section in
      guard let header = tableView.headerView(forSection: section) else { return nil }
      let rect = tableView.rectForHeader(inSection: section)
      return FKStickyTarget(
        id: "header_\(section)",
        viewProvider: { [weak header] in header },
        threshold: rect.minY,
        onStyleChanged: { style, view in
          view.backgroundColor = style == .sticky ? .systemOrange : .tertiarySystemBackground
        }
      )
    }
    tableView.fk_stickyEngine.setTargets(targets)
  }
}
