import UIKit
import FKUIKit

/// UICollectionView swipe demo (no third-party dependency).
///
/// - Highlights:
///   - One-line enablement: `collectionView.fk_enableSwipeActions { ... }`
///   - No custom cell required (uses system cells).
final class FKSwipeActionCollectionScenarioViewController: UIViewController, UICollectionViewDataSource {
  private var items: [Int] = Array(0..<80)
  private let collectionView: UICollectionView

  init() {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 12
    layout.minimumInteritemSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    layout.itemSize = CGSize(width: 160, height: 72)
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UICollectionView: Swipe Actions"
    view.backgroundColor = .systemGroupedBackground

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .clear
    collectionView.dataSource = self
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Key line: enable swipe actions for UICollectionView (no cell subclassing required).
    collectionView.fk_enableSwipeActions { indexPath in
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "delete",
            title: "Delete",
            icon: UIImage(systemName: "trash.fill"),
            background: .color(.systemRed),
            layout: .iconTop,
            width: 84,
            cornerRadius: 14
          ) {},
          FKSwipeActionButton(
            id: "more",
            title: "More",
            icon: UIImage(systemName: "ellipsis"),
            background: .horizontalGradient(leading: .systemBlue, trailing: .systemTeal),
            layout: .iconLeading,
            width: 100,
            cornerRadius: 14
          ) {},
        ],
        allowedDirections: [.left],
        tapToClose: true
      )
    }
  }

  // MARK: - UICollectionViewDataSource

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.backgroundColor = .secondarySystemGroupedBackground
    cell.layer.cornerRadius = 16
    cell.layer.masksToBounds = true

    // Minimal content: use a label to avoid introducing a custom cell.
    let labelTag = 101
    let label: UILabel
    if let existed = cell.contentView.viewWithTag(labelTag) as? UILabel {
      label = existed
    } else {
      label = UILabel()
      label.tag = labelTag
      label.translatesAutoresizingMaskIntoConstraints = false
      label.font = .preferredFont(forTextStyle: .headline)
      cell.contentView.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 14),
        label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    }
    label.text = "Item \(items[indexPath.item])"
    return cell
  }
}

