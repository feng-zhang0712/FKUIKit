import UIKit
import FKUIKit

/// Auto-generated skeletons on visible collection cells (UIImageView + UILabel).
final class FKSkeletonExampleCollectionAutoVisibleViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
    title = "Collection · auto visible"
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

    collectionView.register(FKSkeletonExamplePhotoTileCell.self, forCellWithReuseIdentifier: "tile")
    collectionView.dataSource = self
    collectionView.delegate = self

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle loading",
      style: .done,
      target: self,
      action: #selector(toggle)
    )

    applySkeletonForCurrentState()
  }

  @objc private func toggle() {
    if isLoading {
      collectionView.fk_hideAutoSkeletonOnVisibleCells(animated: true) { [weak self] in
        self?.isLoading = false
        self?.collectionView.reloadData()
      }
    } else {
      isLoading = true
      collectionView.reloadData()
      collectionView.layoutIfNeeded()
      collectionView.fk_showAutoSkeletonOnVisibleCells(
        options: FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true, excludedViews: []),
        animated: true
      )
    }
  }

  private func applySkeletonForCurrentState() {
    collectionView.reloadData()
    if isLoading {
      collectionView.layoutIfNeeded()
      collectionView.fk_showAutoSkeletonOnVisibleCells(
        options: FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true, excludedViews: []),
        animated: false
      )
    }
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    10
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tile", for: indexPath) as! FKSkeletonExamplePhotoTileCell
    cell.titleLabel.text = "Photo \(indexPath.item + 1)"
    cell.imageView.image = UIImage(systemName: "photo.fill.on.rectangle.fill")
    cell.imageView.tintColor = .tertiaryLabel
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let inset = flow.sectionInset.left + flow.sectionInset.right + flow.minimumInteritemSpacing
    let w = (collectionView.bounds.width - inset) / 2
    return CGSize(width: floor(w), height: 204)
  }
}
