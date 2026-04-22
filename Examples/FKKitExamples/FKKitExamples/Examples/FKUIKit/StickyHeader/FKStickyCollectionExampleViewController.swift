import FKUIKit
import UIKit

/// Demonstrates sticky behavior for collection section headers.
final class FKStickyCollectionExampleViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
  private var collectionView: UICollectionView!
  private let sections = Array(0..<10)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection Sticky Header"
    view.backgroundColor = .systemBackground
    setupCollectionView()
    setupSticky()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.frame = view.bounds
    reloadStickyTargets()
  }

  private func setupCollectionView() {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = .init(width: view.bounds.width - 32, height: 56)
    layout.minimumLineSpacing = 8
    layout.headerReferenceSize = .init(width: view.bounds.width, height: 52)

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemBackground
    collectionView.contentInset = .init(top: 8, left: 0, bottom: 16, right: 0)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.register(FKStickySectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
    view.addSubview(collectionView)
  }

  private func setupSticky() {
    var configuration = FKStickyConfiguration.default
    configuration.additionalTopInset = 4
    collectionView.fk_stickyEngine.apply(configuration: configuration)
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    4
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.backgroundColor = .secondarySystemGroupedBackground
    cell.layer.cornerRadius = 12
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    guard kind == UICollectionView.elementKindSectionHeader else {
      return UICollectionReusableView()
    }
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: "header",
      for: indexPath
    ) as! FKStickySectionHeaderView
    header.configure(title: "Section Header \(indexPath.section)")
    return header
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    scrollView.fk_handleStickyScroll()
  }

  private func reloadStickyTargets() {
    let targets: [FKStickyTarget] = sections.compactMap { section in
      let indexPath = IndexPath(item: 0, section: section)
      guard
        let header = collectionView.supplementaryView(
          forElementKind: UICollectionView.elementKindSectionHeader,
          at: indexPath
        )
      else {
        return nil
      }
      guard let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(
        ofKind: UICollectionView.elementKindSectionHeader,
        at: indexPath
      ) else {
        return nil
      }
      return FKStickyTarget(
        id: "collection_header_\(section)",
        viewProvider: { [weak header] in header },
        threshold: attributes.frame.minY,
        onStyleChanged: { style, view in
          view.backgroundColor = style == .sticky ? .systemGreen : .tertiarySystemBackground
        }
      )
    }
    collectionView.fk_stickyEngine.setTargets(targets)
  }
}

private final class FKStickySectionHeaderView: UICollectionReusableView {
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .tertiarySystemBackground
    titleLabel.font = .boldSystemFont(ofSize: 16)
    titleLabel.frame = .init(x: 16, y: 0, width: frame.width - 32, height: frame.height)
    titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(titleLabel)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String) {
    titleLabel.text = title
  }
}
