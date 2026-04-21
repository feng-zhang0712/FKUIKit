//
// FKSwipeActionCollectionExampleViewController.swift
//
// UICollectionView demo for FKSwipeAction left-swipe multi-button scenarios.
//

import FKUIKit
import UIKit

/// Demonstrates left swipe multi-buttons on `UICollectionViewCell`.
///
/// Covered scenarios:
/// - Multiple left-swipe buttons
/// - Text-only / image-only / image+text
/// - Adaptive and fixed widths
/// - Callback handling and per-cell swipe disable
/// - Auto-close behavior on list scroll
final class FKSwipeActionCollectionExampleViewController: UIViewController {
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 12
    layout.minimumInteritemSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemGroupedBackground
    view.register(FKSwipeDemoCollectionCell.self, forCellWithReuseIdentifier: FKSwipeDemoCollectionCell.reuseID)
    view.dataSource = self
    view.delegate = self
    return view
  }()

  private var items: [String] = (1...40).map { "Card \($0)" }
  private var disabledIndices = Set<Int>([1, 5, 9])
  private var pinnedIndices = Set<Int>()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection Swipe (Left)"
    view.backgroundColor = .systemBackground
    setupLayout()
  }

  private func setupLayout() {
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func buildLeftActions(for indexPath: IndexPath) -> [FKSwipeActionItem] {
    let index = indexPath.item

    // Image-only fixed width button.
    let pinStyle = FKSwipeActionItemStyle(
      fixedWidth: 60,
      cornerRadius: 12,
      contentInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
      backgroundColor: .systemOrange,
      imageTintColor: .white,
      imageSize: CGSize(width: 17, height: 17)
    )

    let pin = FKSwipeActionItem.pin(
      title: nil,
      image: UIImage(systemName: "pin.fill"),
      style: pinStyle
    ) { [weak self] _ in
      guard let self else { return }
      if self.pinnedIndices.contains(index) {
        self.pinnedIndices.remove(index)
      } else {
        self.pinnedIndices.insert(index)
      }
      self.collectionView.reloadItems(at: [indexPath])
    }

    // Text-only adaptive width button.
    let editStyle = FKSwipeActionItemStyle(
      fixedWidth: nil,
      minimumWidth: 78,
      cornerRadius: 12,
      contentInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
      backgroundColor: .systemBlue,
      titleColor: .white,
      titleFont: .systemFont(ofSize: 13, weight: .semibold)
    )

    let edit = FKSwipeActionItem.edit(title: "Edit", style: editStyle) { [weak self] _ in
      self?.presentHint("Edit tapped @ item \(index)")
    }

    // Image+text adaptive width button.
    let favoriteStyle = FKSwipeActionItemStyle(
      fixedWidth: nil,
      minimumWidth: 94,
      cornerRadius: 12,
      contentInsets: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10),
      imageTitleSpacing: 4,
      backgroundColor: .systemPink,
      titleColor: .white,
      titleFont: .systemFont(ofSize: 13, weight: .bold),
      imageTintColor: .white,
      imageSize: CGSize(width: 16, height: 16)
    )

    let favorite = FKSwipeActionItem.favorite(
      title: "Favorite",
      image: UIImage(systemName: "heart.fill"),
      style: favoriteStyle
    ) { [weak self] _ in
      self?.presentHint("Favorite tapped @ item \(index)")
    }

    return [pin, edit, favorite]
  }

  private func presentHint(_ message: String) {
    let alert = UIAlertController(title: "Callback", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - UICollectionViewDataSource

extension FKSwipeActionCollectionExampleViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: FKSwipeDemoCollectionCell.reuseID,
      for: indexPath
    ) as? FKSwipeDemoCollectionCell else {
      return UICollectionViewCell()
    }

    let isPinned = pinnedIndices.contains(indexPath.item)
    let subtitle = disabledIndices.contains(indexPath.item) ? "Swipe disabled" : "Swipe left-to-right for actions"
    cell.render(title: items[indexPath.item], subtitle: subtitle, isPinned: isPinned)

    // One-line setup API for left swipe multi-buttons.
    cell.fk_configureSwipeActions(left: buildLeftActions(for: indexPath))
    cell.fk_setSwipeActionEnabled(!disabledIndices.contains(indexPath.item))

    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FKSwipeActionCollectionExampleViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let width = collectionView.bounds.width - 32
    return CGSize(width: width, height: 82)
  }
}

// MARK: - Demo Cell

private final class FKSwipeDemoCollectionCell: UICollectionViewCell {
  static let reuseID = "FKSwipeDemoCollectionCell"

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let pinBadge = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Explicitly close state to avoid reused-cell swipe mismatch.
    fk_closeSwipeAction(animated: false)
  }

  func render(title: String, subtitle: String, isPinned: Bool) {
    titleLabel.text = title
    subtitleLabel.text = subtitle
    pinBadge.isHidden = !isPinned
  }

  private func setupViews() {
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 12
    contentView.layer.masksToBounds = true

    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .label

    subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel

    pinBadge.font = .systemFont(ofSize: 11, weight: .bold)
    pinBadge.textColor = .white
    pinBadge.backgroundColor = .systemOrange
    pinBadge.textAlignment = .center
    pinBadge.text = "PINNED"
    pinBadge.layer.cornerRadius = 8
    pinBadge.layer.masksToBounds = true
    pinBadge.isHidden = true

    [titleLabel, subtitleLabel, pinBadge].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview($0)
    }

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: pinBadge.leadingAnchor, constant: -10),
      subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),

      pinBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
      pinBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      pinBadge.widthAnchor.constraint(equalToConstant: 56),
      pinBadge.heightAnchor.constraint(equalToConstant: 20)
    ])
  }
}
