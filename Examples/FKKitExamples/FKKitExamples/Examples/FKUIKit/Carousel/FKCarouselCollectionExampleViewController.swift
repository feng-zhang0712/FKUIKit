//
// FKCarouselCollectionExampleViewController.swift
//
// UICollectionView reuse-safe FKCarousel example.
//

import FKUIKit
import UIKit

/// Demonstrates FKCarousel usage in reusable collection view cells.
final class FKCarouselCollectionExampleViewController: UICollectionViewController {
  private let values = Array(0..<30)

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
    collectionView.register(FKCarouselCollectionCell.self, forCellWithReuseIdentifier: FKCarouselCollectionCell.reuseID)
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    values.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKCarouselCollectionCell.reuseID, for: indexPath) as? FKCarouselCollectionCell else {
      return UICollectionViewCell()
    }
    cell.configure(index: values[indexPath.item], vertical: indexPath.item % 4 == 0)
    return cell
  }
}

extension FKCarouselCollectionExampleViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (collectionView.bounds.width - 16 * 2 - 12) / 2
    return CGSize(width: width, height: 182)
  }
}

private final class FKCarouselCollectionCell: UICollectionViewCell {
  static let reuseID = "FKCarouselCollectionCell"

  private let titleLabel = UILabel()
  private let carousel = FKCarousel()

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
    carousel.onPageChanged = nil
    carousel.onItemSelected = nil
  }

  func configure(index: Int, vertical: Bool) {
    titleLabel.text = vertical ? "No. \(index) · Vertical" : "No. \(index) · Horizontal"
    var config = FKCarouselConfiguration()
    config.autoScrollInterval = 2.8
    config.direction = vertical ? .vertical : .horizontal
    config.pageControlAlignment = .center
    config.containerStyle.cornerRadius = 10
    carousel.apply(configuration: config)
    carousel.reload(items: FKCarouselDemoSupport.localImageItems())
  }

  private func setupUI() {
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 12
    contentView.layer.masksToBounds = true

    titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    carousel.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(carousel)
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

      carousel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      carousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
      carousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
      carousel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }
}
