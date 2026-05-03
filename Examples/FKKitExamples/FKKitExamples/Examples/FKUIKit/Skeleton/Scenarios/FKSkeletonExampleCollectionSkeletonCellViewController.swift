import UIKit
import FKUIKit

/// Flow layout grid using `FKSkeletonCollectionViewCell`.
final class FKSkeletonExampleCollectionSkeletonCellViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  private enum Reuse {
    static let skeleton = "skeleton.collection"
    static let tile = "tile"
  }

  private lazy var flow: UICollectionViewFlowLayout = {
    let f = UICollectionViewFlowLayout()
    f.minimumInteritemSpacing = 12
    f.minimumLineSpacing = 16
    f.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    return f
  }()

  private lazy var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)

  private var isLoading = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection · skeleton cell"
    view.backgroundColor = .systemBackground

    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    collectionView.register(FKSkeletonCollectionViewCell.self, forCellWithReuseIdentifier: Reuse.skeleton)
    collectionView.register(FKSkeletonExamplePhotoTileCell.self, forCellWithReuseIdentifier: Reuse.tile)
    collectionView.dataSource = self
    collectionView.delegate = self

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle loaded",
      style: .done,
      target: self,
      action: #selector(toggleLoaded)
    )
  }

  @objc private func toggleLoaded() {
    isLoading.toggle()
    collectionView.reloadData()
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    isLoading ? 6 : 12
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if isLoading {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.skeleton, for: indexPath) as! FKSkeletonCollectionViewCell
      if cell.skeletonContainer.skeletonSubviews.isEmpty {
        Self.configureGridSkeleton(cell)
      }
      cell.skeletonContainer.showSkeleton(animated: false)
      return cell
    }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Reuse.tile, for: indexPath) as! FKSkeletonExamplePhotoTileCell
    cell.titleLabel.text = "Item \(indexPath.item + 1)"
    cell.imageView.image = UIImage(systemName: "photo")
    cell.imageView.tintColor = .secondaryLabel
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let inset = flow.sectionInset.left + flow.sectionInset.right + flow.minimumInteritemSpacing
    let w = (collectionView.bounds.width - inset) / 2
    let h: CGFloat = isLoading ? 192 : 200
    return CGSize(width: floor(w), height: h)
  }

  private static func configureGridSkeleton(_ cell: FKSkeletonCollectionViewCell) {
    cell.resetSkeletonContent()
    let c = cell.skeletonContainer
    let image = FKSkeletonView()
    image.layer.cornerRadius = 10
    let label = FKSkeletonView()
    label.layer.cornerRadius = 4
    [image, label].forEach { c.addSkeletonSubview($0) }
    NSLayoutConstraint.activate([
      image.topAnchor.constraint(equalTo: c.topAnchor),
      image.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      image.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      image.heightAnchor.constraint(equalTo: image.widthAnchor),

      label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 10),
      label.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      label.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 0.85),
      label.heightAnchor.constraint(equalToConstant: 12),
      label.bottomAnchor.constraint(equalTo: c.bottomAnchor),
    ])
  }
}
