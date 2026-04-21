//
// FKCarouselTableExampleViewController.swift
//
// UITableView reuse-safe FKCarousel example.
//

import FKUIKit
import UIKit

/// Demonstrates FKCarousel usage in reusable table view cells.
final class FKCarouselTableExampleViewController: UITableViewController {
  private let rows = (0..<24).map { "Table Row \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TableView Cells"
    tableView.register(FKCarouselTableCell.self, forCellReuseIdentifier: FKCarouselTableCell.reuseID)
    tableView.rowHeight = 196
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: FKCarouselTableCell.reuseID, for: indexPath) as? FKCarouselTableCell else {
      return UITableViewCell()
    }
    let useSingle = indexPath.row % 5 == 0
    cell.configure(title: rows[indexPath.row], singleMode: useSingle)
    return cell
  }
}

private final class FKCarouselTableCell: UITableViewCell {
  static let reuseID = "FKCarouselTableCell"

  private let titleLabel = UILabel()
  private let carousel = FKCarousel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reset callbacks to avoid retaining stale references in reusable cells.
    carousel.onItemSelected = nil
    carousel.onPageChanged = nil
  }

  func configure(title: String, singleMode: Bool) {
    titleLabel.text = singleMode ? "\(title) · Single Item" : "\(title) · Infinite Loop"
    var config = FKCarouselConfiguration()
    config.autoScrollInterval = 2.2
    config.containerStyle.cornerRadius = 10
    carousel.apply(configuration: config)
    carousel.reload(items: singleMode ? FKCarouselDemoSupport.singleImageItem() : FKCarouselDemoSupport.localImageItems())
  }

  private func setupUI() {
    selectionStyle = .none
    titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    carousel.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(carousel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

      carousel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      carousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      carousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      carousel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
    ])
  }
}
