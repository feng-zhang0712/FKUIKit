//
// FKStarRatingTableExampleViewController.swift
//
// UITableView reuse adaptation demo for FKStarRating.
//

import FKUIKit
import UIKit

/// Demonstrates `FKStarRating` integration in reusable table cells.
final class FKStarRatingTableExampleViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var items: [FKStarRatingRowModel] = FKStarRatingRowModel.makeMockData()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "StarRating Table"
    view.backgroundColor = .systemBackground
    setupTableView()
  }
}

private extension FKStarRatingTableExampleViewController {
  func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(FKStarRatingDemoCell.self, forCellReuseIdentifier: FKStarRatingDemoCell.reuseIdentifier)
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 88
    tableView.dataSource = self
    tableView.delegate = self
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension FKStarRatingTableExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: FKStarRatingDemoCell.reuseIdentifier, for: indexPath) as? FKStarRatingDemoCell else {
      return UITableViewCell()
    }
    let model = items[indexPath.row]
    cell.bind(model: model) { [weak self] updated in
      self?.items[indexPath.row] = updated
    }
    return cell
  }
}

extension FKStarRatingTableExampleViewController: UITableViewDelegate {}

// MARK: - Cell

private final class FKStarRatingDemoCell: UITableViewCell {
  static let reuseIdentifier = "FKStarRatingDemoCell"

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let ratingView = FKStarRating()
  private var currentModel: FKStarRatingRowModel?
  private var onModelUpdate: ((FKStarRatingRowModel) -> Void)?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupLayout()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupLayout()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reset callbacks/state to avoid reuse disorder.
    ratingView.prepareForReuse()
    currentModel = nil
    onModelUpdate = nil
  }

  func bind(model: FKStarRatingRowModel, onUpdate: @escaping (FKStarRatingRowModel) -> Void) {
    currentModel = model
    onModelUpdate = onUpdate
    titleLabel.text = model.title
    subtitleLabel.text = model.subtitle

    ratingView.configure {
      $0.mode = .half
      $0.starCount = 5
      $0.starSize = CGSize(width: 22, height: 22)
      $0.starSpacing = 6
      $0.isEditable = model.isEditable
      $0.minimumRating = 0
      $0.maximumRating = 5
      $0.renderMode = .color
      $0.selectedColor = .systemYellow
      $0.unselectedColor = .systemGray4
      $0.allowsContinuousPan = true
    }
    ratingView.setRating(model.rating, notify: false)

    ratingView.onRatingChanged = { [weak self] value in
      guard var updated = self?.currentModel else { return }
      updated.rating = value
      self?.currentModel = updated
      self?.onModelUpdate?(updated)
    }
    ratingView.onRatingCommit = { [weak self] value in
      guard var updated = self?.currentModel else { return }
      updated.rating = value
      self?.currentModel = updated
      self?.onModelUpdate?(updated)
    }
  }
}

private extension FKStarRatingDemoCell {
  func setupLayout() {
    selectionStyle = .none

    titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 1

    subtitleLabel.font = .systemFont(ofSize: 13)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, ratingView])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
      ratingView.heightAnchor.constraint(equalToConstant: 24),
    ])
  }
}

// MARK: - Model

private struct FKStarRatingRowModel: Hashable {
  var id: String
  var title: String
  var subtitle: String
  var rating: CGFloat
  var isEditable: Bool

  static func makeMockData() -> [FKStarRatingRowModel] {
    [
      FKStarRatingRowModel(
        id: "goods_1",
        title: "Wireless Headphones",
        subtitle: "Editable row. Try sliding to rate continuously.",
        rating: 4.5,
        isEditable: true
      ),
      FKStarRatingRowModel(
        id: "goods_2",
        title: "Coffee Grinder",
        subtitle: "Editable row. Tap any star to commit score.",
        rating: 3,
        isEditable: true
      ),
      FKStarRatingRowModel(
        id: "goods_3",
        title: "Ceramic Mug",
        subtitle: "Display-only row. Used for score presentation.",
        rating: 4,
        isEditable: false
      ),
      FKStarRatingRowModel(
        id: "goods_4",
        title: "Desk Lamp",
        subtitle: "Editable row. Reuse-safe callback binding.",
        rating: 2.5,
        isEditable: true
      ),
    ]
  }
}
