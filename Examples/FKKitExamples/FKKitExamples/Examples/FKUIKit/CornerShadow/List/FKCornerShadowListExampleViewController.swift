//
// FKCornerShadowListExampleViewController.swift
//
// UITableViewCell and UICollectionViewCell FKCornerShadow examples.
//

import UIKit
import FKUIKit

/// Demonstrates cell reuse safety and list performance patterns.
final class FKCornerShadowListExampleViewController: UIViewController {
  private lazy var segmented: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Table", "Collection"])
    control.selectedSegmentIndex = 0
    control.translatesAutoresizingMaskIntoConstraints = false
    control.addAction(UIAction { [weak self] _ in self?.syncMode() }, for: .valueChanged)
    return control
  }()

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var collectionView: UICollectionView!
  private let items = Array(1...20).map { "Card \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table & Collection"
    view.backgroundColor = .systemGroupedBackground
    setupCollectionView()
    setupLayout()
    syncMode()
  }

  private func setupLayout() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FKCornerShadowTableCell.self, forCellReuseIdentifier: "tableCell")
    tableView.dataSource = self
    tableView.rowHeight = 92

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(FKCornerShadowCollectionCell.self, forCellWithReuseIdentifier: "collectionCell")
    collectionView.dataSource = self

    view.addSubview(segmented)
    view.addSubview(tableView)
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 10),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      collectionView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 10),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupCollectionView() {
    let layout = UICollectionViewFlowLayout()
    let width = (UIScreen.main.bounds.width - 12 * 2 - 10) / 2
    layout.itemSize = CGSize(width: width, height: 118)
    layout.minimumLineSpacing = 10
    layout.minimumInteritemSpacing = 10
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
  }

  private func syncMode() {
    let showTable = segmented.selectedSegmentIndex == 0
    tableView.isHidden = !showTable
    collectionView.isHidden = showTable
  }
}

extension FKCornerShadowListExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as? FKCornerShadowTableCell else {
      return UITableViewCell()
    }
    cell.configure(text: items[indexPath.row])
    return cell
  }
}

extension FKCornerShadowListExampleViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as? FKCornerShadowCollectionCell else {
      return UICollectionViewCell()
    }
    cell.configure(text: items[indexPath.item])
    return cell
  }
}

/// Reuse-safe table cell demo.
private final class FKCornerShadowTableCell: UITableViewCell {
  private let card = UIView()
  private let titleLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    card.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
    titleLabel.textColor = .label
    contentView.addSubview(card)
    card.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
      titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
      titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Always reset in reusable cells to avoid style accumulation.
    card.fk_resetCornerShadow()
  }

  func configure(text: String) {
    titleLabel.text = "UITableViewCell - \(text)"
    card.fk_applyCornerShadowFromGlobal { style in
      style.cornerRadius = 16
      style.corners = .allCorners
      style.fillColor = .systemBackground
      style.shadow = FKCornerShadowShadow(opacity: 0.12, offset: CGSize(width: 0, height: 3), blur: 9, spread: 0, sides: [.bottom])
    }
  }
}

/// Reuse-safe collection cell demo.
private final class FKCornerShadowCollectionCell: UICollectionViewCell {
  private let card = UIView()
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .clear

    card.translatesAutoresizingMaskIntoConstraints = false
    card.backgroundColor = .systemBackground
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 2
    titleLabel.textAlignment = .center
    titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    contentView.addSubview(card)
    card.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
      card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
      card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
      titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    card.fk_resetCornerShadow()
  }

  func configure(text: String) {
    titleLabel.text = "UICollectionViewCell\n\(text)"
    card.fk_applyCornerShadow(
      corners: [.topLeft, .topRight, .bottomRight],
      cornerRadius: 18,
      fillColor: .systemBackground,
      border: .solid(color: .quaternaryLabel, width: 0.6),
      shadow: FKCornerShadowShadow(color: .black, opacity: 0.14, offset: CGSize(width: 0, height: 5), blur: 10, spread: 0, sides: [.bottom])
    )
  }
}
