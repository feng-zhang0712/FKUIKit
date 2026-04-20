//
// FKEmptyStateCollectionViewExampleViewController.swift
//
// Copy-ready collection integration example for FKEmptyState.
//

import FKUIKit
import UIKit

/// Demonstrates FKEmptyState with UICollectionView and manual hide/show controls.
final class FKEmptyStateCollectionViewExampleViewController: UIViewController {
  private var items: [String] = []

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: 150, height: 80)
    layout.minimumLineSpacing = 12
    layout.minimumInteritemSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.translatesAutoresizingMaskIntoConstraints = false
    collection.backgroundColor = .systemBackground
    collection.dataSource = self
    collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    return collection
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UICollectionView Empty State"
    view.backgroundColor = .systemBackground

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Load Data", style: .plain, target: self, action: #selector(loadData)),
      UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearData)),
    ]

    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    showNoNetworkState()
  }

  /// Shows no-network with callback for system settings.
  private func showNoNetworkState() {
    var model = FKEmptyStateDemoFactory.makeNoNetworkModel()
    model.description = "Connection is unavailable. Open Settings to enable network access."
    model.contentAlignment = .center
    collectionView.fk_applyEmptyState(model, actionHandler: {
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    })
  }

  /// Updates placeholder based on collection item count.
  private func refreshPlaceholder() {
    var model = FKEmptyStateDemoFactory.makeCustomEmptyModel()
    model.title = "No Collection Items"
    model.description = "Tap Load Data to generate collection cells."
    model.buttonStyle.title = "Refresh"
    collectionView.fk_updateEmptyState(
      itemCount: items.count,
      model: model,
      actionHandler: { [weak self] in
        self?.loadData()
      }
    )
  }

  @objc private func loadData() {
    items = (1...20).map { "Card \($0)" }
    collectionView.reloadData()
    refreshPlaceholder()
  }

  @objc private func clearData() {
    items.removeAll()
    collectionView.reloadData()
    refreshPlaceholder()
  }
}

extension FKEmptyStateCollectionViewExampleViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.backgroundColor = .secondarySystemBackground
    cell.layer.cornerRadius = 10

    let tag = 2026
    let label: UILabel
    if let existing = cell.contentView.viewWithTag(tag) as? UILabel {
      label = existing
    } else {
      label = UILabel()
      label.translatesAutoresizingMaskIntoConstraints = false
      label.tag = tag
      label.font = .systemFont(ofSize: 14, weight: .medium)
      label.textAlignment = .center
      cell.contentView.addSubview(label)
      NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    }

    label.text = items[indexPath.item]
    return cell
  }
}
