//
// FKLoadingAnimatorCollectionExampleViewController.swift
//
// UICollectionView reuse-safe loading animator example.
//

import FKUIKit
import UIKit

/// Demonstrates loading animator usage in reusable collection view cells.
final class FKLoadingAnimatorCollectionExampleViewController: UICollectionViewController {
  private let values = Array(0..<40)

  init() {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 12
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    super.init(collectionViewLayout: layout)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CollectionView Cells"
    collectionView.backgroundColor = .systemBackground
    collectionView.register(FKLoadingAnimatorCollectionCell.self, forCellWithReuseIdentifier: FKLoadingAnimatorCollectionCell.reuseID)
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    values.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKLoadingAnimatorCollectionCell.reuseID, for: indexPath) as? FKLoadingAnimatorCollectionCell else {
      return UICollectionViewCell()
    }
    cell.configure(text: "No. \(values[indexPath.item])", isLoading: indexPath.item % 2 == 0)
    return cell
  }
}

extension FKLoadingAnimatorCollectionExampleViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (collectionView.bounds.width - 16 * 2 - 12) / 2
    return CGSize(width: width, height: 120)
  }
}

private final class FKLoadingAnimatorCollectionCell: UICollectionViewCell {
  static let reuseID = "FKLoadingAnimatorCollectionCell"

  private let label = UILabel()
  private let loadingHost = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    loadingHost.fk_hideLoadingAnimator(animated: false)
  }

  func configure(text: String, isLoading: Bool) {
    label.text = text
    if isLoading {
      loadingHost.fk_showLoadingAnimator { config in
        config.presentationMode = .embedded
        config.style = .pulseSquare
        config.size = CGSize(width: 46, height: 46)
        config.styleConfiguration.primaryColor = .systemPurple
      }
    } else {
      loadingHost.fk_hideLoadingAnimator(animated: false)
    }
  }

  private func setupUI() {
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 12
    contentView.layer.masksToBounds = true

    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .label

    loadingHost.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(label)
    contentView.addSubview(loadingHost)

    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

      loadingHost.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      loadingHost.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10),
      loadingHost.widthAnchor.constraint(equalToConstant: 56),
      loadingHost.heightAnchor.constraint(equalToConstant: 56),
    ])
  }
}

