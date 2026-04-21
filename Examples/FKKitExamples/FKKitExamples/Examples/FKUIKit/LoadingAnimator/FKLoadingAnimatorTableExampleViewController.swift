//
// FKLoadingAnimatorTableExampleViewController.swift
//
// UITableView reuse-safe loading animator example.
//

import FKUIKit
import UIKit

/// Demonstrates loading animator usage in reusable table view cells.
final class FKLoadingAnimatorTableExampleViewController: UITableViewController {
  private var items: [String] = (0..<30).map { "Table Item \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TableView Cells"
    tableView.register(FKLoadingAnimatorTableCell.self, forCellReuseIdentifier: FKLoadingAnimatorTableCell.reuseID)
    tableView.rowHeight = 72
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: FKLoadingAnimatorTableCell.reuseID, for: indexPath) as? FKLoadingAnimatorTableCell else {
      return UITableViewCell()
    }
    cell.configure(title: items[indexPath.row], isLoading: indexPath.row % 3 != 0)
    return cell
  }
}

private final class FKLoadingAnimatorTableCell: UITableViewCell {
  static let reuseID = "FKLoadingAnimatorTableCell"

  private let titleLabel = UILabel()
  private let loadingHost = UIView()

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
    // Always reset loading host on reuse to avoid state mismatch.
    loadingHost.fk_hideLoadingAnimator(animated: false)
  }

  func configure(title: String, isLoading: Bool) {
    titleLabel.text = title
    if isLoading {
      loadingHost.fk_showLoadingAnimator { config in
        config.presentationMode = .embedded
        config.style = .rotatingDots
        config.size = CGSize(width: 36, height: 36)
        config.backgroundColor = .clear
      }
    } else {
      loadingHost.fk_hideLoadingAnimator(animated: false)
    }
  }

  private func setupUI() {
    selectionStyle = .none
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    loadingHost.translatesAutoresizingMaskIntoConstraints = false
    loadingHost.backgroundColor = .clear

    contentView.addSubview(titleLabel)
    contentView.addSubview(loadingHost)

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

      loadingHost.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      loadingHost.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      loadingHost.widthAnchor.constraint(equalToConstant: 40),
      loadingHost.heightAnchor.constraint(equalToConstant: 40),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: loadingHost.leadingAnchor, constant: -12),
    ])
  }
}

