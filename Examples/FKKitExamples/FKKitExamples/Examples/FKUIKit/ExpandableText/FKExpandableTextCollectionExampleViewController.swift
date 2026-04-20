//
// FKExpandableTextCollectionExampleViewController.swift
//
// UICollectionView demo for FKExpandableText in reusable card cells.
//

import FKUIKit
import UIKit

/// Demonstrates expandable text adaptation in `UICollectionViewCell`.
///
/// Covered scenarios:
/// - Expandable text in UICollectionViewCell
/// - Reuse-safe state cache with stable model id
/// - Attributed/plain text mixed content
/// - Callback-driven list relayout
final class FKExpandableTextCollectionExampleViewController: UIViewController {
  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 12
    layout.minimumInteritemSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .systemGroupedBackground
    view.register(FKExpandableTextCollectionCell.self, forCellWithReuseIdentifier: FKExpandableTextCollectionCell.reuseID)
    view.dataSource = self
    view.delegate = self
    return view
  }()

  private var items: [DemoItem] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection Expandable"
    view.backgroundColor = .systemBackground
    items = Self.makeItems()
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
}

// MARK: - UICollectionViewDataSource

extension FKExpandableTextCollectionExampleViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: FKExpandableTextCollectionCell.reuseID,
      for: indexPath
    ) as? FKExpandableTextCollectionCell else {
      return UICollectionViewCell()
    }

    let item = items[indexPath.item]
    cell.render(item: item)
    cell.fk_bindExpandableText(cell.expandableText, key: item.id, defaultExpanded: false)
    if let attributed = item.attributedContent {
      cell.expandableText.setAttributedText(attributed, stateIdentifier: item.id)
    } else {
      cell.expandableText.setText(item.content, stateIdentifier: item.id)
    }

    cell.expandableText.onStateChange = { [weak collectionView] _ in
      collectionView?.performBatchUpdates(nil)
    }
    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FKExpandableTextCollectionExampleViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let width = collectionView.bounds.width - 32
    let item = items[indexPath.item]
    let text = item.content
    let attributed = item.attributedContent
    let state = FKExpandableText.stateCache.state(for: item.id) ?? .collapsed
    let estimatedTextHeight = FKExpandableText.preferredHeight(
      text: text,
      attributedText: attributed,
      width: width - 24,
      state: state,
      cacheKey: "collection_height_\(item.id)_\(state)"
    )
    return CGSize(width: width, height: 56 + estimatedTextHeight)
  }
}

// MARK: - Demo Cell

private final class FKExpandableTextCollectionCell: UICollectionViewCell {
  static let reuseID = "FKExpandableTextCollectionCell"

  let titleLabel = UILabel()
  let expandableText = FKExpandableText()

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
    expandableText.onStateChange = nil
  }

  func render(item: FKExpandableTextCollectionExampleViewController.DemoItem) {
    titleLabel.text = item.title
    expandableText.configure {
      $0.behavior.collapsedNumberOfLines = 3
      $0.behavior.triggerMode = .all
      $0.textStyle.font = .systemFont(ofSize: 14)
      $0.textStyle.lineSpacing = 4
      $0.textStyle.color = .label
      $0.buttonStyle.expandTitle = "Read More"
      $0.buttonStyle.collapseTitle = "Collapse"
      $0.buttonStyle.titleColor = .systemBlue
      $0.buttonStyle.highlightedTitleColor = .systemGray
      $0.layoutStyle.animationDuration = 0.25
      $0.layoutStyle.buttonPosition = .bottomTrailing
    }
  }

  private func setupViews() {
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.layer.cornerRadius = 12
    contentView.layer.masksToBounds = true

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    titleLabel.textColor = .label

    expandableText.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(titleLabel)
    contentView.addSubview(expandableText)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

      expandableText.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      expandableText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
      expandableText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
      expandableText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
    ])
  }
}

fileprivate extension FKExpandableTextCollectionExampleViewController {
  struct DemoItem {
    let id: String
    let title: String
    let content: String
    let attributedContent: NSAttributedString?
  }

  static func makeItems() -> [DemoItem] {
    (1...30).map { index in
      if index.isMultiple(of: 4) {
        let attributed = NSMutableAttributedString(
          string: """
          This attributed card #\(index) highlights keywords with custom color.
          Reuse state is restored using the same stable model identifier.
          """
        )
        attributed.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 5, length: 10))
        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: NSRange(location: 5, length: 10))
        return DemoItem(
          id: "collection_demo_\(index)",
          title: "Card #\(index) (Attributed)",
          content: "",
          attributedContent: attributed
        )
      } else {
        return DemoItem(
          id: "collection_demo_\(index)",
          title: "Card #\(index)",
          content: """
          FKExpandableText works in collection cells and supports manual or callback-driven layout updates.
          This is sample content for index \(index), used to verify expand/collapse behavior during fast scrolling.
          """,
          attributedContent: nil
        )
      }
    }
  }
}
